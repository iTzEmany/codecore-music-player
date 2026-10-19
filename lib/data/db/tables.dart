import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/uuid.dart';

@TableIndex(name: 'tracks_album_key', columns: {#albumKey})
@TableIndex(name: 'tracks_artist', columns: {#artist})
@TableIndex(name: 'tracks_favorite', columns: {#isFavorite})
@TableIndex(name: 'tracks_kind', columns: {#kind})
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

  /// Hidden by the user (a duplicate that was merged away). Unlike `missing`
  /// the scanner never clears it; «Brani nascosti» does.
  BoolColumn get ignored => boolean().withDefault(const Constant(false))();

  /// 0 music · 1 a downloaded podcast episode. Every music view filters
  /// `kind = 0`: episodes never show up in the library.
  IntColumn get kind => integer().withDefault(const Constant(0))();
  TextColumn get sha256 => text().nullable()();
  IntColumn get addedAt => integer()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  RealColumn get replayGainDb => real().nullable()();

  /// «Riprendi da qui»: where a long track (≥ 20 min) was left; null = none.
  IntColumn get resumePositionMs => integer().nullable()();
  IntColumn get lastPlayedAt => integer().nullable()();
}

class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  IntColumn get addedAt => integer()();
  TextColumn get label => text().nullable()();
}

@TableIndex(name: 'playlists_uuid', columns: {#uuid}, unique: true)
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();

  /// Identity of the playlist across devices (schema v10): the same on every
  /// device it is synced to. Nullable only because the migration adds the
  /// column before filling it; every new row gets one.
  TextColumn get uuid => text().nullable().clientDefault(newUuid)();

  /// Epoch ms of the last change to its name, cover, tracks or order: «last
  /// change wins» when playlists are synced.
  IntColumn get updatedAt => integer().withDefault(const Constant(0)).clientDefault(nowMs)();

  /// File name inside the covers folder; null = use the first track's cover.
  TextColumn get coverKey => text().nullable()();
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

/// One CSV import (Exportify) into a playlist. See `docs/fase-12-import-csv.md`.
class PlaylistImports extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceName => text()();
  IntColumn get createdAt => integer()();

  /// 0 running · 1 paused · 2 finished · 3 cancelled.
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// Where the rows came from: `exportify` · `tunemymusic` · `soundiiz` ·
  /// `lastfm` · `csv` · `m3u` · `xspf`.
  TextColumn get sourceKind => text().withDefault(const Constant('exportify'))();

  /// Sub-folder of the download folder for this import (null = none).
  TextColumn get folderPath => text().nullable()();

  /// Prefix downloaded files with their position (`007 - Artist - Title`).
  BoolColumn get numberFiles => boolean().withDefault(const Constant(false))();

  /// Link what the library has and download nothing.
  BoolColumn get linkOnly => boolean().withDefault(const Constant(false))();

  /// Search everything first and wait for the user before downloading.
  BoolColumn get planFirst => boolean().withDefault(const Constant(false))();

  /// Look the album cover up after each download.
  BoolColumn get fetchCovers => boolean().withDefault(const Constant(false))();
}

/// One row of the CSV, in playlist order.
class PlaylistImportItems extends Table {
  IntColumn get importId =>
      integer().references(PlaylistImports, #id, onDelete: KeyAction.cascade)();
  IntColumn get rowIndex => integer()();
  TextColumn get title => text()();

  /// Artists joined with `;` (the CSV separator, so never inside a name).
  TextColumn get artists => text()();
  TextColumn get album => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get isrc => text().nullable()();

  /// 0 to search · 1 queued · 2 downloaded · 3 linked (already in library)
  /// · 4 to review · 5 not found · 6 failed · 7 skipped by the user
  /// · 8 planned (chosen, waiting for «Download») · 9 removed from the source.
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get videoId => text().nullable()();

  /// JSON list of the best candidates, kept while status is 4 (to review).
  TextColumn get candidates => text().nullable()();
  IntColumn get trackId => integer()
      .nullable()
      .references(Tracks, #id, onDelete: KeyAction.setNull)();
  RealColumn get score => real().nullable()();

  /// Why a row is «not found» or «to review» (shown and exported).
  TextColumn get note => text().nullable()();

  /// Path or URL of a local M3U/XSPF entry.
  TextColumn get location => text().nullable()();

  @override
  Set<Column> get primaryKey => {importId, rowIndex};
}

/// One listen: a track that played past the «counts as played» threshold.
/// The history starts empty (nothing is invented from `play_count`).
// Covering: a recap can group a year of listens by track from the index alone.
@TableIndex(name: 'plays_track', columns: {#trackId, #playedAt, #msPlayed})
@TableIndex(name: 'plays_at', columns: {#playedAt})
class Plays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();

  /// Epoch ms of the moment it counted as played.
  IntColumn get playedAt => integer()();

  /// Time really spent playing it (seeks do not count); grows until the
  /// track changes.
  IntColumn get msPlayed => integer().withDefault(const Constant(0))();

  /// `PlayContextKind.index` of where it was started from, if known.
  IntColumn get context => integer().nullable()();
  TextColumn get contextName => text().nullable()();
}

/// A playlist defined by rules (text in the rule language), computed live.
class SmartPlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get rules => text()();

  /// `SortOption` name, or `random`; null = the default order.
  TextColumn get sort => text().nullable()();
  IntColumn get limitCount => integer().nullable()();
  IntColumn get createdAt => integer()();
}

/// The user's own labels for tracks (distinct from the file tags).
class UserTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();

  /// Index of one of the eight accent tokens; null = none.
  IntColumn get color => integer().nullable()();
}

class TrackTags extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(UserTags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {trackId, tagId};
}

/// A podcast the user subscribed to by its RSS address.
class Podcasts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get feedUrl => text().unique()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();

  /// Where the cover comes from (the feed's image).
  TextColumn get imageUrl => text().nullable()();

  /// File name inside the covers folder, once downloaded.
  TextColumn get coverKey => text().nullable()();
  TextColumn get language => text().nullable()();

  /// Epoch ms of the last successful refresh; null = never.
  IntColumn get lastCheckedAt => integer().nullable()();

  /// Delete played episodes after this many days; null = never.
  IntColumn get autoDeleteDays => integer().nullable()();
  IntColumn get addedAt => integer()();
}

/// One episode of a feed. Downloaded ones also have a `tracks` row (kind 1),
/// linked by [trackId]; the others are only listed.
@TableIndex(name: 'podcast_episodes_podcast', columns: {#podcastId, #publishedAt})
class PodcastEpisodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get podcastId =>
      integer().references(Podcasts, #id, onDelete: KeyAction.cascade)();
  TextColumn get guid => text()();
  TextColumn get title => text()();
  IntColumn get publishedAt => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get audioUrl => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get trackId => integer()
      .nullable()
      .references(Tracks, #id, onDelete: KeyAction.setNull)();
  BoolColumn get played => boolean().withDefault(const Constant(false))();
  IntColumn get playedAt => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {podcastId, guid},
      ];
}

/// What Wikipedia says about an artist, kept once per artist (not per track)
/// so every track of theirs shows it without asking again.
class ArtistInfos extends Table {
  /// `matchKey` of the main artist's name.
  TextColumn get artistKey => text()();
  TextColumn get body => text()();
  TextColumn get sourceUrl => text()();
  TextColumn get lang => text()();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {artistKey};
}
