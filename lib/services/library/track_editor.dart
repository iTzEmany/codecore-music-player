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
