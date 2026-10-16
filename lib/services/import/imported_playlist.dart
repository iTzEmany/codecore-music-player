import '../../core/import_row.dart';

export '../../core/import_row.dart';

/// A playlist read from a file, whatever its format.
class ImportedPlaylist {
  const ImportedPlaylist({
    required this.name,
    required this.rows,
    this.skipped = 0,
    this.kind = 'exportify',
  });

  final String name;
  final List<ImportRow> rows;

  /// Rows left out: no title, podcast episodes, local files, unreadable lines.
  final int skipped;

  /// Source format, stored with the import: `exportify`, `tunemymusic`,
  /// `soundiiz`, `lastfm`, `csv`, `m3u` or `xspf`.
  final String kind;
}
