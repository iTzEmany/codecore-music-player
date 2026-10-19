import 'package:drift/drift.dart';

import '../../services/library/rules/rule_rewrite.dart';
import '../db/app_database.dart';

/// A tag with the number of tracks that carry it.
class TagSummary {
  const TagSummary(this.tag, this.trackCount);

  final UserTag tag;
  final int trackCount;
}

/// The user's own labels for tracks. They are user data: nothing here ever
/// removes one by itself (deleting a tag only unlinks it from its tracks).
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  Stream<List<TagSummary>> watchAll() {
    final count = _db.trackTags.trackId.count();
    final q = _db.select(_db.userTags).join([
      leftOuterJoin(_db.trackTags, _db.trackTags.tagId.equalsExp(_db.userTags.id)),
    ])
      ..addColumns([count])
      ..groupBy([_db.userTags.id])
      ..orderBy([OrderingTerm(expression: _db.userTags.name.lower())]);
    return q.watch().map((rows) => [
          for (final r in rows) TagSummary(r.readTable(_db.userTags), r.read(count) ?? 0),
        ]);
  }

  Future<UserTag?> byName(String name) => (_db.select(_db.userTags)
        ..where((t) => t.name.equals(name.trim())))
      .getSingleOrNull();

  /// Makes a tag, or returns the one that already has this name (case is
  /// ignored: «Live» and «live» are one tag).
  Future<int> create(String name, {int? color}) async {
    final clean = name.trim();
    final existing = await byName(clean);
    if (existing != null) return existing.id;
    return _db.into(_db.userTags).insert(UserTagsCompanion.insert(
          name: clean,
          color: Value(color),
        ));
  }

  /// Renames a tag; the smart playlists that cite its name follow it. Returns
  /// false when another tag already has the new name.
  Future<bool> rename(int id, String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return false;
    return _db.transaction(() async {
      final old = await (_db.select(_db.userTags)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (old == null) return false;
      final clash = await byName(clean);
      if (clash != null && clash.id != id) return false;
      await (_db.update(_db.userTags)..where((t) => t.id.equals(id)))
          .write(UserTagsCompanion(name: Value(clean)));
      for (final p in await _db.select(_db.smartPlaylists).get()) {
        final rewritten = renameTagInRules(p.rules, old.name, clean);
        if (rewritten != null) {
          await (_db.update(_db.smartPlaylists)..where((x) => x.id.equals(p.id)))
              .write(SmartPlaylistsCompanion(rules: Value(rewritten)));
        }
      }
      return true;
    });
  }

  Future<void> setColor(int id, int? color) =>
      (_db.update(_db.userTags)..where((t) => t.id.equals(id)))
          .write(UserTagsCompanion(color: Value(color)));

  /// Removes the tag and its links; the tracks are untouched.
  Future<void> delete(int id) =>
      (_db.delete(_db.userTags)..where((t) => t.id.equals(id))).go();

  /// How many of [trackIds] carry each tag (only tags carried by at least one).
  Future<Map<int, int>> countsAmong(List<int> trackIds) async {
    if (trackIds.isEmpty) return const {};
    final count = _db.trackTags.trackId.count();
    final rows = await (_db.selectOnly(_db.trackTags)
          ..addColumns([_db.trackTags.tagId, count])
          ..where(_db.trackTags.trackId.isIn(trackIds))
          ..groupBy([_db.trackTags.tagId]))
        .get();
    return {
      for (final r in rows) r.read(_db.trackTags.tagId)!: r.read(count) ?? 0,
    };
  }

  /// Gives [tagId] to every track in one transaction (those that have it
  /// already are left alone). Returns how many got it now.
  Future<int> assign(List<int> trackIds, int tagId) => _db.transaction(() async {
        final have = {
          for (final r in await (_db.select(_db.trackTags)
                ..where((t) => t.tagId.equals(tagId)))
              .get())
            r.trackId,
        };
        var added = 0;
        for (final id in trackIds) {
          if (!have.add(id)) continue;
          await _db.into(_db.trackTags).insert(
              TrackTagsCompanion.insert(trackId: id, tagId: tagId));
          added++;
        }
        return added;
      });

  /// Takes [tagId] away from the tracks. Returns how many lost it.
  Future<int> unassign(List<int> trackIds, int tagId) => _db.transaction(() async {
        var removed = 0;
        for (var i = 0; i < trackIds.length; i += 500) {
          final chunk = trackIds.sublist(i, (i + 500).clamp(0, trackIds.length));
          removed += await (_db.delete(_db.trackTags)
                ..where((t) => t.tagId.equals(tagId) & t.trackId.isIn(chunk)))
              .go();
        }
        return removed;
      });
}
