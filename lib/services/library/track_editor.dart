import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/text_utils.dart';
import '../../data/db/app_database.dart';
import '../tags/tag_reader.dart';

class TrackEdit {
  const TrackEdit({
    required this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.year,
    this.trackNumber,
    this.genre,
  });

  final String title;
  final String? artist, album, albumArtist, genre;
  final int? year, trackNumber;
}

String? _blankToNull(String? s) {
  final t = s?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// Edits live only in the DB; the audio files are never rewritten.
class TrackEditor {
  TrackEditor(this._db, this._tags);

  final AppDatabase _db;
  final TagReader _tags;

  Future<void> save(Track track, TrackEdit e) async {
    final artist = _blankToNull(e.artist);
    final album = _blankToNull(e.album);
    final albumArtist = _blankToNull(e.albumArtist);
    final key = computeAlbumKey(
      albumArtist: albumArtist,
      artist: artist,
      album: album,
      directory: p.dirname(track.path),
    );
    await (_db.update(_db.tracks)..where((t) => t.id.equals(track.id))).write(
      TracksCompanion(
        title: Value(e.title.trim()),
        artist: Value(artist),
        album: Value(album),
        albumArtist: Value(albumArtist),
        year: Value(e.year),
        trackNumber: Value(e.trackNumber),
        genre: Value(_blankToNull(e.genre)),
        albumKey: Value(key),
        userEdited: const Value(true),
      ),
    );
  }

  /// Puts [tracks] in the album [album] by [albumArtist] (merging with it if
  /// it exists, creating it if not) in one transaction. Like [save] it marks
  /// them as edited and never touches a file. With [cover] the tracks take
  /// that cover, so a merged album shows the one of the album chosen as main.
  /// Returns what each track was before, for [restoreMany].
  Future<List<Track>> saveMany(
    List<Track> tracks, {
    required String album,
    required String albumArtist,
    ({bool hasCover, String? coverKey})? cover,
  }) async {
    final al = _blankToNull(album);
    final aa = _blankToNull(albumArtist);
    await _db.transaction(() async {
      for (final t in tracks) {
        await (_db.update(_db.tracks)..where((r) => r.id.equals(t.id))).write(
          TracksCompanion(
            album: Value(al),
            albumArtist: Value(aa),
            albumKey: Value(
              computeAlbumKey(
                albumArtist: aa,
                artist: t.artist,
                album: al,
                directory: p.dirname(t.path),
              ),
            ),
            userEdited: const Value(true),
            hasCover: cover == null ? const Value.absent() : Value(cover.hasCover),
            coverKey: cover == null ? const Value.absent() : Value(cover.coverKey),
          ),
        );
      }
    });
    return tracks;
  }

  /// Undoes [saveMany]: [before] are the tracks as it returned them.
  Future<void> restoreMany(List<Track> before) => _db.transaction(() async {
    for (final t in before) {
      await (_db.update(_db.tracks)..where((r) => r.id.equals(t.id))).write(
        TracksCompanion(
          album: Value(t.album),
          albumArtist: Value(t.albumArtist),
          albumKey: Value(t.albumKey),
          userEdited: Value(t.userEdited),
          hasCover: Value(t.hasCover),
          coverKey: Value(t.coverKey),
        ),
      );
    }
  });

  Future<void> restoreFromFile(Track track) async {
    final t = await _tags.read(track.path, withCover: false);
    final dir = p.dirname(track.path);
    final key = computeAlbumKey(
      albumArtist: t.albumArtist,
      artist: t.artist,
      album: t.album,
      directory: dir,
    );
    await (_db.update(_db.tracks)..where((r) => r.id.equals(track.id))).write(
      TracksCompanion(
        title: Value(t.title ?? p.basenameWithoutExtension(track.path)),
        artist: Value(t.artist),
        album: Value(t.album),
        albumArtist: Value(t.albumArtist),
        year: Value(t.year),
        trackNumber: Value(t.trackNumber),
        genre: Value(t.genre),
        albumKey: Value(key),
        userEdited: const Value(false),
      ),
    );
  }
}
