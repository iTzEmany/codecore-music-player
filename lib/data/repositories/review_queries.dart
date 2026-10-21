import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'light_tracks.dart';

/// Why a track is listed in «Da revisionare».
enum ReviewReason { nothingFound, noLyrics, noCover, missingData }

/// All the reasons that apply to [t] (a list row: `lyricsPlain` is `''` when
/// the text exists, null when it does not).
Set<ReviewReason> reviewReasons(Track t) => {
  if (t.enrichStatus == 2) ReviewReason.nothingFound,
  if (t.lyricsPlain == null && t.lyricsSynced == null) ReviewReason.noLyrics,
  if (!t.hasCover) ReviewReason.noCover,
  if (t.album == null || t.year == null || t.genre == null)
    ReviewReason.missingData,
};

/// Music that online enrichment already tried (status 1 or 2) and that still
/// lacks something. Status 0 is «not tried yet», so it is not listed.
class ReviewQueries {
  ReviewQueries(this._db);

  final AppDatabase _db;

  Expression<bool> _where($TracksTable t, Set<int> dismissed) =>
      t.kind.equals(0) &
      t.missing.equals(false) &
      t.ignored.equals(false) &
      t.enrichStatus.isIn(const [1, 2]) &
      (t.enrichStatus.equals(2) |
          (t.lyricsPlain.isNull() & t.lyricsSynced.isNull()) |
          t.hasCover.equals(false) |
          t.album.isNull() |
          t.year.isNull() |
          t.genre.isNull()) &
      (dismissed.isEmpty ? const Constant(true) : t.id.isNotIn(dismissed));

  Stream<List<Track>> watch({Set<int> dismissed = const {}}) => lightSelect(
    _db,
    _db.select(_db.tracks)
      ..where((t) => _where(t, dismissed))
      ..orderBy([
        (t) => OrderingTerm(expression: t.title.collate(Collate.noCase)),
      ]),
  ).watch();

  Stream<int> watchCount({Set<int> dismissed = const {}}) {
    final n = _db.tracks.id.count();
    return (_db.selectOnly(_db.tracks)
          ..addColumns([n])
          ..where(_where(_db.tracks, dismissed)))
        .map((r) => r.read(n) ?? 0)
        .watchSingle();
  }

  /// Back to «not tried yet», so the enrichment looks at them again.
  Future<void> resetStatus(Set<int> ids) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      final all = ids.toList();
      for (var i = 0; i < all.length; i += 500) {
        final chunk = all.sublist(
          i,
          i + 500 > all.length ? all.length : i + 500,
        );
        await (_db.update(_db.tracks)..where((t) => t.id.isIn(chunk))).write(
          const TracksCompanion(enrichStatus: Value(0)),
        );
      }
    });
  }
}
