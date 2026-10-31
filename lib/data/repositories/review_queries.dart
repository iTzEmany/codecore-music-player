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
/// D-286: a hand-written text (`lyricsByUser`) is not «no lyrics»; stream rows
/// and a missing track number stay out of the review on purpose.
class ReviewQueries {
  ReviewQueries(this._db);

  final AppDatabase _db;

  Expression<bool> _where($TracksTable t, Set<int> dismissed) =>
      t.kind.equals(0) &
      t.missing.equals(false) &
      t.ignored.equals(false) &
      t.enrichStatus.isIn(const [1, 2]) &
      (t.enrichStatus.equals(2) |
          (t.lyricsPlain.isNull() &
              t.lyricsSynced.isNull() &
              notExistsQuery(
                _db.selectOnly(_db.trackEnrich)
                  ..addColumns([_db.trackEnrich.trackId])
                  ..where(
                    _db.trackEnrich.trackId.equalsExp(t.id) &
                        _db.trackEnrich.lyricsByUser.equals(true),
                  ),
              )) |
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
  ).watch().asyncMap(_userLyricsAsText);

  /// A list row has `''` for a text that exists: a hand-written one counts, so
  /// [reviewReasons] does not call the row «no lyrics».
  Future<List<Track>> _userLyricsAsText(List<Track> rows) async {
    final none = [
      for (final t in rows)
        if (t.lyricsPlain == null && t.lyricsSynced == null) t.id,
    ];
    if (none.isEmpty) return rows;
    final byUser = {
      for (final e in await (_db.select(_db.trackEnrich)
            ..where((e) => e.trackId.isIn(none) & e.lyricsByUser.equals(true)))
          .get())
        e.trackId,
    };
    if (byUser.isEmpty) return rows;
    return [
      for (final t in rows)
        byUser.contains(t.id) ? t.copyWith(lyricsPlain: const Value('')) : t,
    ];
  }

  Stream<int> watchCount({Set<int> dismissed = const {}}) {
    final n = _db.tracks.id.count();
    return (_db.selectOnly(_db.tracks)
          ..addColumns([n])
          ..where(_where(_db.tracks, dismissed)))
        .map((r) => r.read(n) ?? 0)
        .watchSingle();
  }
}
