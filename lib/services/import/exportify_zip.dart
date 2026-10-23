import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../core/app_log.dart';
import 'csv_profiles.dart';
import 'imported_playlist.dart';

const kMaxZipBytes = 20 * 1024 * 1024;
const kMaxZipEntries = 300;
const kMaxZipTotalBytes = 50 * 1024 * 1024;

class ExportifyZipResult {
  const ExportifyZipResult(this.entries, this.skipped);

  /// CSV entry file name (as in the ZIP) and the playlist read from it.
  final List<({String fileName, ImportedPlaylist playlist})> entries;

  /// CSV entries left out: unreadable, other columns, or too big.
  final int skipped;
}

/// Reads the playlists of an Exportify «Export All» ZIP in a background
/// isolate. Throws [CsvTooLargeException] when the ZIP is over a limit.
Future<ExportifyZipResult> readExportifyZip(Uint8List bytes) =>
    Isolate.run(() => _readZip(bytes));

ExportifyZipResult _readZip(Uint8List bytes) {
  if (bytes.length > kMaxZipBytes) {
    throw CsvTooLargeException('ZIP of ${bytes.length} bytes');
  }
  final archive = ZipDecoder().decodeBytes(bytes);
  if (archive.length > kMaxZipEntries) {
    throw CsvTooLargeException('ZIP with ${archive.length} entries');
  }
  final entries = <({String fileName, ImportedPlaylist playlist})>[];
  var skipped = 0;
  var total = 0;
  for (final f in archive) {
    final name = f.name;
    if (!f.isFile ||
        name.contains('/') ||
        !name.toLowerCase().endsWith('.csv')) {
      continue;
    }
    // The declared size is checked before anything is extracted.
    if (f.size > kMaxCsvBytes) {
      AppLog.w('Exportify ZIP: $name skipped, ${f.size} bytes');
      skipped++;
      continue;
    }
    total += f.size;
    if (total > kMaxZipTotalBytes) {
      throw CsvTooLargeException('ZIP content over $kMaxZipTotalBytes bytes');
    }
    try {
      final text = utf8.decode(f.content, allowMalformed: true);
      entries.add((fileName: name, playlist: readCsvPlaylist(name, text)));
    } on FormatException catch (e) {
      AppLog.w('Exportify ZIP: $name skipped', e);
      skipped++;
    }
  }
  return ExportifyZipResult(entries, skipped);
}

/// Exportify's file name for a playlist name, lower case.
String exportifyKey(String name) => name.toLowerCase().replaceAll(
  RegExp(r'[\x00-\x1F\x7F/\\<>:;"|=,.?*\[\]\s]+'),
  '_',
);

/// What Codecore knows of a playlist: [lastImportName] is the source name of
/// its latest import, if any.
typedef ExportifyPlaylistRef = ({int id, String name, String? lastImportName});

/// Where a ZIP entry goes: [playlistId] set = that playlist; [ambiguous] = the
/// user chooses; neither = a new playlist.
typedef ExportifyMatch = ({int? playlistId, bool ambiguous});

final _dupSuffix = RegExp(r' \(\d+\)$');

/// One match per entry file name, in order. Never guesses: a ` (1)` suffix or
/// several playlists with the same key is [ExportifyMatch.ambiguous].
List<ExportifyMatch> matchExportifyEntries(
  List<String> fileNames,
  List<ExportifyPlaylistRef> playlists,
) {
  return [
    for (final file in fileNames)
      () {
        final stem = file
            .replaceFirst(RegExp(r'\.csv$', caseSensitive: false), '')
            .toLowerCase();
        if (_dupSuffix.hasMatch(stem)) {
          return (playlistId: null, ambiguous: true);
        }
        final hits = [
          for (final p in playlists)
            if (exportifyKey(p.name) == stem ||
                (p.lastImportName != null &&
                    (p.lastImportName!.toLowerCase() == file.toLowerCase() ||
                        exportifyKey(p.lastImportName!) == stem)))
              p.id,
        ];
        if (hits.length > 1) return (playlistId: null, ambiguous: true);
        return (playlistId: hits.firstOrNull, ambiguous: false);
      }(),
  ];
}
