import 'dart:isolate';

import 'csv_parser.dart';
import 'imported_playlist.dart';

export 'imported_playlist.dart';

/// A playlist CSV is a few hundred KB; anything near these limits is not one.
const kMaxCsvBytes = 5 * 1024 * 1024;
const kMaxCsvRows = 10000;

class CsvTooLargeException extends FormatException {
  const CsvTooLargeException(super.message);
}

/// Throws [CsvTooLargeException] before the file is read into memory.
void checkCsvSize(int bytes) {
  if (bytes > kMaxCsvBytes) {
    throw CsvTooLargeException('CSV of $bytes bytes exceeds $kMaxCsvBytes');
  }
}

/// Kept for the callers and tests written when Exportify was the only source.
typedef ExportifyPlaylist = ImportedPlaylist;

const _titleHeaders = ['track name', 'name', 'title'];
const _artistHeaders = ['artist name(s)', 'artist name', 'artists', 'artist'];
const _albumHeaders = ['album name', 'album'];
const _durationHeaders = ['duration (ms)', 'track duration (ms)'];
const _uriHeaders = ['track uri', 'spotify uri', 'spotify id'];

int? _col(List<String> header, List<String> names) {
  for (final n in names) {
    final i = header.indexOf(n);
    if (i >= 0) return i;
  }
  return null;
}

String? _cell(List<String> row, int? i) {
  if (i == null || i >= row.length) return null;
  final v = row[i].trim();
  return v.isEmpty ? null : v;
}

/// Exportify names the file after the playlist, with spaces turned into `_`.
String playlistNameFromFile(String fileName) {
  final base = fileName.split(RegExp(r'[\\/]')).last;
  final noExt = base.replaceFirst(RegExp(r'\.csv$', caseSensitive: false), '');
  final name = noExt.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return name.isEmpty ? 'Playlist' : name;
}

/// Throws [FormatException] when [text] does not look like an Exportify file.
ImportedPlaylist readExportify(String fileName, String text) {
  final table = parseCsv(text);
  if (table.isEmpty) {
    throw const FormatException('not an Exportify file: empty');
  }
  if (table.length - 1 > kMaxCsvRows) {
    throw CsvTooLargeException('CSV with ${table.length - 1} rows');
  }
  final header = [for (final h in table.first) h.trim().toLowerCase()];
  final titleCol = _col(header, _titleHeaders);
  final artistCol = _col(header, _artistHeaders);
  if (titleCol == null || artistCol == null) {
    throw const FormatException('not an Exportify file: missing columns');
  }
  final albumCol = _col(header, _albumHeaders);
  final durationCol = _col(header, _durationHeaders);
  final isrcCol = _col(header, const ['isrc']);
  final uriCol = _col(header, _uriHeaders);

  final rows = <ImportRow>[];
  var skipped = 0;
  for (final r in table.skip(1)) {
    final title = _cell(r, titleCol);
    final uri = _cell(r, uriCol);
    final isTrack = uri == null ||
        !(uri.startsWith('spotify:episode:') || uri.startsWith('spotify:local:'));
    if (title == null || !isTrack) {
      skipped++;
      continue;
    }
    final artists = [
      for (final a in (_cell(r, artistCol) ?? '').split(';'))
        if (a.trim().isNotEmpty) a.trim(),
    ];
    rows.add(ImportRow(
      index: rows.length,
      title: title,
      artists: artists,
      album: _cell(r, albumCol),
      durationMs: int.tryParse(_cell(r, durationCol) ?? ''),
      isrc: _cell(r, isrcCol),
      spotifyUri: uri,
    ));
  }
  return ImportedPlaylist(
    name: playlistNameFromFile(fileName),
    rows: rows,
    skipped: skipped,
  );
}

/// Same as [readExportify], off the UI thread (a CSV can have thousands of rows).
Future<ImportedPlaylist> readExportifyInIsolate(String fileName, String text) =>
    Isolate.run(() => readExportify(fileName, text));
