import 'package:drift/drift.dart';

@TableIndex(name: 'tracks_album_key', columns: {#albumKey})
@TableIndex(name: 'tracks_artist', columns: {#artist})
@TableIndex(name: 'tracks_favorite', columns: {#isFavorite})
@TableIndex(name: 'tracks_missing', columns: {#missing})
@TableIndex(name: 'tracks_title', columns: {#title})
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  IntColumn get folderId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumKey => text()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get format => text()();
  IntColumn get sampleRateHz => integer().nullable()();
  IntColumn get bitDepth => integer().nullable()();
  IntColumn get bitrateKbps => integer().nullable()();
  IntColumn get channels => integer().nullable()();
  IntColumn get sizeBytes => integer()();
  IntColumn get mtimeMs => integer()();
  BoolColumn get hasCover => boolean().withDefault(const Constant(false))();
  TextColumn get coverKey => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get lyricsPlain => text().nullable()();
  TextColumn get lyricsSynced => text().nullable()();
  TextColumn get curiosities => text().nullable()();
  IntColumn get enrichStatus => integer().withDefault(const Constant(0))();
  BoolColumn get userEdited => boolean().withDefault(const Constant(false))();
  BoolColumn get missing => boolean().withDefault(const Constant(false))();
  TextColumn get sha256 => text().nullable()();
  IntColumn get addedAt => integer()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get lastPlayedAt => integer().nullable()();
}

class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  IntColumn get addedAt => integer()();
  TextColumn get label => text().nullable()();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
}

@TableIndex(name: 'playlist_tracks_track', columns: {#trackId})
class PlaylistTracks extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}
