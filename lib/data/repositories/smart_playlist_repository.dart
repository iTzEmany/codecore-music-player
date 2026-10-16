import 'package:drift/drift.dart';

import '../../services/library/rules/rule_parser.dart';
import '../db/app_database.dart';
import 'track_repository.dart';

/// How a smart playlist is ordered (stored by name).
enum SmartSort {
  defaultOrder,
  title,
  artist,
  album,
  year,
  addedAt,
  duration,
  mostPlayed,
  random;

  static SmartSort fromName(String? name) => SmartSort.values.firstWhere(
    (s) => s.name == name,
    orElse: () => SmartSort.defaultOrder,
  );

  /// The library order it maps to (the ones that are not special).
  SortOption get sortOption => switch (this) {
    SmartSort.title => SortOption.title,
    SmartSort.artist => SortOption.artist,
    SmartSort.album => SortOption.album,
    SmartSort.year => SortOption.year,
    SmartSort.addedAt => SortOption.addedAt,
    SmartSort.duration => SortOption.duration,
    _ => SortOption.defaultOrder,
  };
}

/// Playlists defined by rules in the search language, computed live from the
/// library: they have no rows in `playlist_tracks`.
class SmartPlaylistRepository {
  SmartPlaylistRepository(this._db, this._tracks);

  final AppDatabase _db;
  final TrackRepository _tracks;

  Stream<List<SmartPlaylist>> watchAll() =>
      (_db.select(_db.smartPlaylists)
            ..orderBy([(p) => OrderingTerm(expression: p.name.lower())]))
          .watch();

  Future<List<SmartPlaylist>> getAll() => _db.select(_db.smartPlaylists).get();

  Future<SmartPlaylist?> get(int id) => (_db.select(
    _db.smartPlaylists,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Stream<SmartPlaylist?> watch(int id) => (_db.select(
    _db.smartPlaylists,
  )..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<int> create({
    required String name,
    required String rules,
    SmartSort sort = SmartSort.defaultOrder,
    int? limit,
  }) => _db.into(_db.smartPlaylists).insert(
        SmartPlaylistsCompanion.insert(
          name: name.trim(),
          // Stored in the canonical form, so editing it later starts clean.
          rules: formatRules(parseRules(rules).expr),
          sort: Value(sort == SmartSort.defaultOrder ? null : sort.name),
          limitCount: Value(limit),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<void> update(
    int id, {
    String? name,
    String? rules,
    SmartSort? sort,
    int? limit,
    bool clearLimit = false,
  }) => (_db.update(_db.smartPlaylists)..where((p) => p.id.equals(id))).write(
        SmartPlaylistsCompanion(
          name: name == null ? const Value.absent() : Value(name.trim()),
          rules: rules == null
              ? const Value.absent()
              : Value(formatRules(parseRules(rules).expr)),
          sort: sort == null
              ? const Value.absent()
              : Value(sort == SmartSort.defaultOrder ? null : sort.name),
          limitCount: clearLimit
              ? const Value(null)
              : limit == null
                  ? const Value.absent()
                  : Value(limit),
        ),
      );

  Future<void> delete(int id) =>
      (_db.delete(_db.smartPlaylists)..where((p) => p.id.equals(id))).go();

  /// The tracks of [p], kept up to date. A «random» order is the same for the
  /// same [randomSeed] (one per session), so the list does not reshuffle
  /// every time something changes.
  Stream<List<Track>> watchTracks(SmartPlaylist p, {int randomSeed = 1}) =>
      _tracks.watchByRules(
        parseRules(p.rules).expr,
        sort: SmartSort.fromName(p.sort).sortOption,
        limit: p.limitCount,
        mostPlayed: SmartSort.fromName(p.sort) == SmartSort.mostPlayed,
        randomSeed:
            SmartSort.fromName(p.sort) == SmartSort.random ? randomSeed : null,
      );

  Future<List<Track>> tracksOf(SmartPlaylist p, {int randomSeed = 1}) =>
      watchTracks(p, randomSeed: randomSeed).first;

  /// How many tracks [rules] select (the editor's live preview).
  Future<int> count(String rules) =>
      _tracks.countByRules(parseRules(rules).expr);
}
