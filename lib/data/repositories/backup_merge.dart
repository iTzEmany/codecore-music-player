import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/text_utils.dart';
import '../../services/backup/track_resolver.dart';
import '../../services/backup/user_data.dart';
import '../db/app_database.dart';

class MergeReport {
  MergeReport();

  int recognized = 0;
  int favoritesAdded = 0;
  int playlistsCreated = 0;
  int playlistItemsSkipped = 0;

  /// Titles of the tracks the backup mentions that this library does not have.
  final List<String> notFound = [];

  @override
  String toString() => 'MergeReport($recognized recognized, ${notFound.length} not found, '
      '$favoritesAdded favourites, $playlistsCreated playlists)';
}

bool _blank(String? s) => s == null || s.trim().isEmpty;

/// Merges [data] into this library in one transaction and deletes nothing:
/// a favourite is added (never removed), a hand edit applies only to a track
/// the user has not edited here, lyrics fill only empty fields, plays keep the
/// highest count and the latest date. Playlists are created, never merged: an
/// existing name gets «(ripristinata)». Imports are not merged (they depend
/// on the other device's downloads).
Future<MergeReport> mergeUserData(AppDatabase db, UserData data, TrackResolver resolver) {
  final report = MergeReport();
  return db.transaction(() async {
    for (final u in data.tracks) {
      final id = resolver.resolve(u.ref);
      if (id == null) {
        report.notFound.add(u.ref.title);
        continue;
      }
      final t = await (db.select(db.tracks)..where((r) => r.id.equals(id))).getSingleOrNull();
      if (t == null) continue;
      report.recognized++;
      var upd = const TracksCompanion();
      if (u.favorite && !t.isFavorite) {
        upd = upd.copyWith(isFavorite: const Value(true));
        report.favoritesAdded++;
      }
      final e = u.edit;
      if (e != null && !t.userEdited) {
        final artist = _blankToNullTrim(e.artist), album = _blankToNullTrim(e.album);
        final albumArtist = _blankToNullTrim(e.albumArtist);
        upd = upd.copyWith(
          title: Value(e.title.trim()),
          artist: Value(artist),
          album: Value(album),
          albumArtist: Value(albumArtist),
          year: Value(e.year),
          trackNumber: Value(e.trackNumber),
          genre: Value(_blankToNullTrim(e.genre)),
          albumKey: Value(computeAlbumKey(
              albumArtist: albumArtist, artist: artist, album: album, directory: p.dirname(t.path))),
          userEdited: const Value(true),
        );
      }
      if (_blank(t.lyricsPlain) && !_blank(u.lyricsPlain)) upd = upd.copyWith(lyricsPlain: Value(u.lyricsPlain));
      if (_blank(t.lyricsSynced) && !_blank(u.lyricsSynced)) upd = upd.copyWith(lyricsSynced: Value(u.lyricsSynced));
      if (_blank(t.curiosities) && !_blank(u.curiosities)) upd = upd.copyWith(curiosities: Value(u.curiosities));
      if (u.playCount > t.playCount) upd = upd.copyWith(playCount: Value(u.playCount));
      final last = u.lastPlayedAt;
      if (last != null && (t.lastPlayedAt == null || last > t.lastPlayedAt!)) {
        upd = upd.copyWith(lastPlayedAt: Value(last));
      }
      await (db.update(db.tracks)..where((r) => r.id.equals(id))).write(upd);
    }

    final names = {for (final p in await db.select(db.playlists).get()) p.name};
    for (final pl in data.playlists) {
      var name = pl.name;
      if (names.contains(name)) {
        name = '${pl.name} (ripristinata)';
        for (var n = 2; names.contains(name); n++) {
          name = '${pl.name} (ripristinata $n)';
        }
      }
      names.add(name);
      final playlistId = await db.into(db.playlists).insert(
          PlaylistsCompanion.insert(name: name, createdAt: pl.createdAt, coverKey: Value(pl.coverKey)));
      final seen = <int>{};
      var position = 0;
      for (final ref in pl.items) {
        final id = resolver.resolve(ref);
        if (id == null) {
          report.playlistItemsSkipped++;
          continue;
        }
        if (!seen.add(id)) continue;
        await db.into(db.playlistTracks).insert(
            PlaylistTracksCompanion.insert(playlistId: playlistId, trackId: id, position: position++));
      }
      report.playlistsCreated++;
    }
    return report;
  });
}

String? _blankToNullTrim(String? s) => _blank(s) ? null : s!.trim();
