import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../data/db/app_database.dart';
import '../backup/user_data.dart';
import '../import/csv_parser.dart';

/// M3U8 (UTF-8). Paths are absolute, or relative to [relativeTo] with `/`.
String toM3u8(String name, List<Track> tracks, {String? relativeTo}) {
  final b = StringBuffer('#EXTM3U\n#PLAYLIST:$name\n');
  for (final t in tracks) {
    final secs = t.durationMs > 0 ? (t.durationMs / 1000).round() : -1;
    final label = t.artist == null || t.artist!.isEmpty
        ? t.title
        : '${t.artist} - ${t.title}';
    final path = relativeTo == null
        ? t.path
        : p.relative(t.path, from: relativeTo).replaceAll(r'\', '/');
    b.write('#EXTINF:$secs,$label\n$path\n');
  }
  return b.toString();
}

const exportifyHeader = [
  'Track URI',
  'Track Name',
  'Album Name',
  'Artist Name(s)',
  'Duration (ms)',
  'ISRC',
];

/// Same column names Exportify uses, so `readExportify` reads it back.
String toExportifyCsv(List<Track> tracks, Map<int, String> isrcByTrack) =>
    writeCsv([
      exportifyHeader,
      for (final t in tracks)
        [
          '',
          t.title,
          t.album ?? '',
          t.artist ?? '',
          t.durationMs > 0 ? '${t.durationMs}' : '',
          isrcByTrack[t.id] ?? '',
        ],
    ]);

String toPlaylistJson(PlaylistData playlist) =>
    const JsonEncoder.withIndent('  ').convert({
      'format': kUserDataFormat,
      'playlists': [playlist.toJson()],
    });
