import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../services/releases/release_diff.dart';
import '../db/app_database.dart';

/// A stored release with its artist, as Home and «Nuove uscite» list it.
class RecentRelease {
  const RecentRelease(this.release, this.artistName, this.artistMuted, this.variants);

  final ArtistRelease release;
  final String artistName;
  final bool artistMuted;

  /// Other stored versions of the same title («e altre N versioni»).
  final int variants;
}

/// What the artist pages showed: new releases and the past around them.
class ReleaseRepository {
  ReleaseRepository(this._db, {int Function()? now}) : _now = now ?? nowMs;

  final AppDatabase _db;
  final int Function() _now;

  Future<Set<String>> knownIds(String artistId) async => {
        for (final r in await (_db.selectOnly(_db.artistReleases)
              ..addColumns([_db.artistReleases.browseId])
              ..where(_db.artistReleases.artistId.equals(artistId)))
            .get())
          r.read(_db.artistReleases.browseId)!,
      };

  /// `kind:groupKey` of what is stored for the artist (see [releaseGroupId]).
  Future<Set<String>> knownGroups(String artistId) async => {
        for (final r in await (_db.select(_db.artistReleases)
              ..where((r) => r.artistId.equals(artistId)))
            .get())
          releaseGroupId(ReleaseKind.values[r.kind], r.groupKey),
      };

  /// Stores the releases of [diff] in one transaction: the new ones are
  /// flagged (one per group; its variants are stored as past), the rest is
  /// the past. Already stored ids are left as they are.
  Future<void> store(String artistId, ReleaseDiff diff) => _db.transaction(() async {
        final freshIds = {for (final f in diff.fresh) f.release.browseId};
        final at = _now();
        await _db.batch((b) {
          b.insertAll(
            _db.artistReleases,
            [
              for (final s in diff.toStore)
                ArtistReleasesCompanion.insert(
                  browseId: s.release.browseId,
                  artistId: artistId,
                  title: s.release.title,
                  kind: s.kind.index,
                  year: Value(s.year),
                  thumbUrl: Value(s.release.thumbnailUrl),
                  firstSeenAt: at,
                  isNew: Value(freshIds.contains(s.release.browseId)),
                  groupKey: s.groupKey,
                ),
            ],
            mode: InsertMode.insertOrIgnore,
          );
        });
      });

  /// Releases flagged new in the last [days] days (by when they were seen),
  /// newest year first; with [onlyNew] only those not opened yet.
  Stream<List<RecentRelease>> watchRecent({int days = 30, bool onlyNew = false}) {
    final since = _now() - Duration(days: days).inMilliseconds;
    final query = _db.select(_db.artistReleases).join([
      innerJoin(_db.followedArtists,
          _db.followedArtists.ytmId.equalsExp(_db.artistReleases.artistId)),
    ])
      ..where(_db.artistReleases.firstSeenAt.isBiggerOrEqualValue(since) &
          _db.followedArtists.excluded.equals(false) &
          (onlyNew
              ? _db.artistReleases.isNew.equals(true)
              : _db.artistReleases.isNew.equals(true) |
                  _db.artistReleases.openedAt.isNotNull()))
      ..orderBy([
        OrderingTerm.desc(_db.artistReleases.year),
        OrderingTerm.desc(_db.artistReleases.firstSeenAt),
      ]);
    return query.watch().asyncMap((rows) async {
      final out = <RecentRelease>[];
      for (final r in rows) {
        final rel = r.readTable(_db.artistReleases);
        final artist = r.readTable(_db.followedArtists);
        final variants = await (_db.selectOnly(_db.artistReleases)
              ..addColumns([_db.artistReleases.browseId.count()])
              ..where(_db.artistReleases.artistId.equals(rel.artistId) &
                  _db.artistReleases.groupKey.equals(rel.groupKey) &
                  _db.artistReleases.kind.equals(rel.kind) &
                  _db.artistReleases.browseId.equals(rel.browseId).not()))
            .map((x) => x.read(_db.artistReleases.browseId.count()) ?? 0)
            .getSingle();
        out.add(RecentRelease(rel, artist.name, artist.muted, variants));
      }
      return out;
    });
  }

  /// The user opened it: the dot goes away, the release stays in the list.
  Future<void> markOpened(String browseId) =>
      (_db.update(_db.artistReleases)..where((r) => r.browseId.equals(browseId)))
          .write(ArtistReleasesCompanion(isNew: const Value(false), openedAt: Value(_now())));

  Future<int> countNew() async {
    final n = _db.artistReleases.browseId.count();
    final q = _db.selectOnly(_db.artistReleases)
      ..addColumns([n])
      ..where(_db.artistReleases.isNew.equals(true));
    return (await q.map((r) => r.read(n)).getSingle()) ?? 0;
  }

  Stream<int> watchCountNew() {
    final n = _db.artistReleases.browseId.count();
    final q = _db.selectOnly(_db.artistReleases)
      ..addColumns([n])
      ..where(_db.artistReleases.isNew.equals(true));
    return q.map((r) => r.read(n) ?? 0).watchSingle();
  }
}
