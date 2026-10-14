import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../core/app_log.dart';
import '../../core/text_utils.dart';
import '../../data/db/app_database.dart';

class ImportSummary {
  const ImportSummary({
    this.favorites = 0,
    this.playlists = 0,
    this.lyrics = 0,
    this.curiosities = 0,
    this.unmatched = 0,
  });

  final int favorites, playlists, lyrics, curiosities, unmatched;
}

class _OldTrack {
  _OldTrack(this.id, this.path, this.title, this.artist, this.favorite,
      this.lyrics, this.curiosities);

  final String id, path;
  final String? title, artist, lyrics, curiosities;
  final bool favorite;
}

String _basename(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  return parts.isEmpty ? path : parts.last;
}

/// Brings favourites, lyrics, trivia and playlists from the old Python app's
/// SQLite file into this app's database. The source file is opened read-only.
class PythonDbImporter {
  PythonDbImporter(this._db);

  final AppDatabase _db;

  Future<ImportSummary> import(String oldDbPath) async {
    final old = sql.sqlite3.open(oldDbPath, mode: sql.OpenMode.readOnly);
    try {
      return await _run(old);
    } finally {
      old.close();
    }
  }

  Future<ImportSummary> _run(sql.Database old) async {
    final oldTracks = <String, _OldTrack>{};
    for (final r in old.select(
        'SELECT id, path, title, artist, is_favorite, lyrics, curiosities '
        'FROM tracks')) {
      final t = _OldTrack(
        '${r['id']}',
        '${r['path'] ?? ''}',
        r['title'] as String?,
        r['artist'] as String?,
        (r['is_favorite'] as int? ?? 0) != 0,
        r['lyrics'] as String?,
        r['curiosities'] as String?,
      );
      oldTracks[t.id] = t;
    }

    final fresh = await _db.select(_db.tracks).get();
    final byName = <String, List<Track>>{};
    final byMeta = <String, List<Track>>{};
    for (final t in fresh) {
      byName.putIfAbsent(_basename(t.path).toLowerCase(), () => []).add(t);
      final key = '${normalize(t.artist ?? '')}|${normalize(t.title)}';
      byMeta.putIfAbsent(key, () => []).add(t);
    }

    Track? match(_OldTrack o) {
      final named = byName[_basename(o.path).toLowerCase()];
      if (named != null && named.length == 1) return named.single;
      if (named != null && named.length > 1) return null; // ambiguous
      final title = o.title;
      if (title == null || title.trim().isEmpty) return null;
      final key = '${normalize(o.artist ?? '')}|${normalize(title)}';
      final meta = byMeta[key];
      return meta != null && meta.length == 1 ? meta.single : null;
    }

    final matched = <String, Track>{}; // old id -> new track
    var unmatched = 0;
    for (final o in oldTracks.values) {
      final m = match(o);
      if (m == null) {
        unmatched++;
      } else {
        matched[o.id] = m;
      }
    }

    var favorites = 0, lyrics = 0, curiosities = 0, playlists = 0;
    await _db.transaction(() async {
      for (final entry in matched.entries) {
        final o = oldTracks[entry.key]!;
        final t = entry.value;
        final changes = TracksCompanion(
          isFavorite: o.favorite && !t.isFavorite
              ? const Value(true)
              : const Value.absent(),
          lyricsPlain: _fillable(o.lyrics, t.lyricsPlain),
          curiosities: _fillable(o.curiosities, t.curiosities),
        );
        if (o.favorite && !t.isFavorite) favorites++;
        if (changes.lyricsPlain.present) lyrics++;
        if (changes.curiosities.present) curiosities++;
        if (changes.isFavorite.present ||
            changes.lyricsPlain.present ||
            changes.curiosities.present) {
          await (_db.update(_db.tracks)..where((r) => r.id.equals(t.id)))
              .write(changes);
        }
      }

      final existingNames =
          (await _db.select(_db.playlists).get()).map((p) => p.name).toSet();
      for (final p in old.select(
          'SELECT id, name, created_at FROM playlists ORDER BY created_at')) {
        var name = '${p['name'] ?? ''}'.trim();
        if (name.isEmpty) name = 'Playlist';
        while (existingNames.contains(name)) {
          name = '$name (importata)';
        }
        existingNames.add(name);
        final id = await _db.into(_db.playlists).insert(
            PlaylistsCompanion.insert(
                name: name,
                createdAt: DateTime.now().millisecondsSinceEpoch));
        var position = 0;
        final seen = <int>{};
        for (final pt in old.select(
            'SELECT track_id FROM playlist_tracks WHERE playlist_id = ? '
            'ORDER BY position',
            [p['id']])) {
          final t = matched['${pt['track_id']}'];
          if (t == null || !seen.add(t.id)) continue;
          await _db.into(_db.playlistTracks).insert(
              PlaylistTracksCompanion.insert(
                  playlistId: id, trackId: t.id, position: position++));
        }
        playlists++;
      }
    });
    AppLog.i('python import: $favorites fav, $playlists playlists, '
        '$lyrics lyrics, $unmatched unmatched');
    return ImportSummary(
      favorites: favorites,
      playlists: playlists,
      lyrics: lyrics,
      curiosities: curiosities,
      unmatched: unmatched,
    );
  }

  Value<String?> _fillable(String? incoming, String? current) {
    final v = incoming?.trim();
    if (v == null || v.isEmpty) return const Value.absent();
    if (current != null && current.isNotEmpty) return const Value.absent();
    return Value(v);
  }
}
