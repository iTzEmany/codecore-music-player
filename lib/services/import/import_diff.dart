import '../../core/import_row.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/import_repository.dart' show PlaylistImportItemX;
import 'track_matcher.dart';

export '../../core/playlist_order.dart';

/// What a refreshed file changes in a playlist that was imported before.
class ImportDiff {
  const ImportDiff({
    this.added = const [],
    this.removed = const [],
    this.kept = const [],
  });

  /// Rows of the new file that match nothing already in the playlist.
  final List<ImportRow> added;

  /// Tracks of the playlist whose row is gone from the file.
  final List<PlaylistImportItem> removed;

  /// Rows that are still there, with the old item (and so the track) they match.
  final List<({PlaylistImportItem old, ImportRow fresh})> kept;
}

String _titleArtistKey(String title, String primaryArtist) =>
    '${matchTitleKey(title)}|${matchKey(primaryArtist)}';

/// Matches [fresh] rows to the [old] items of a playlist, one to one: first by
/// ISRC, then by title and main artist (so a new ISRC for the same song, as
/// when a service re-releases it, still counts as the same song).
ImportDiff diffImport(List<PlaylistImportItem> old, List<ImportRow> fresh) {
  final freeOld = List.of(old);
  final matched = <int, PlaylistImportItem>{};

  PlaylistImportItem? take(bool Function(PlaylistImportItem) test) {
    final i = freeOld.indexWhere(test);
    return i < 0 ? null : freeOld.removeAt(i);
  }

  for (final r in fresh) {
    final isrc = r.isrc;
    if (isrc == null || isrc.isEmpty) continue;
    final hit = take((o) => o.isrc == isrc);
    if (hit != null) matched[r.index] = hit;
  }
  for (final r in fresh) {
    if (matched.containsKey(r.index)) continue;
    final key = _titleArtistKey(r.title, r.primaryArtist);
    final hit = take(
        (o) => _titleArtistKey(o.title, o.toRow().primaryArtist) == key);
    if (hit != null) matched[r.index] = hit;
  }
  return ImportDiff(
    added: [for (final r in fresh) if (!matched.containsKey(r.index)) r],
    removed: freeOld,
    kept: [
      for (final r in fresh)
        if (matched.containsKey(r.index)) (old: matched[r.index]!, fresh: r),
    ],
  );
}
