import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/paths.dart';
import '../data/repositories/import_repository.dart';
import '../core/constants.dart';
import '../data/db/app_database.dart';
import '../services/import/playlist_import_service.dart';
import '../services/import/track_matcher.dart' show MatchThresholds;
import '../services/library/track_editor.dart';
import '../services/online/cached_youtube_service.dart';
import '../services/online/search_cache.dart';
import 'database_providers.dart';
import 'library_providers.dart';
import 'settings_providers.dart';
import 'youtube_providers.dart';

/// Single import engine. Created at app start by the shell, which also turns
/// "running" imports left by the last session into "paused".
/// Disk cache of search answers; only the CSV import reads it.
final searchCacheProvider = Provider<SearchCache>((ref) {
  final cache = SearchCache(
      file: () async => File(p.join(await appSupportDir(), 'search_cache.json')));
  ref.onDispose(() => unawaited(cache.flush()));
  return cache;
});

final cachedYoutubeProvider = Provider<CachedYoutubeService>((ref) =>
    CachedYoutubeService(
        ref.watch(youtubeServiceProvider), ref.watch(searchCacheProvider)));

/// Number of cached searches, for the settings.
final searchCacheCountProvider = FutureProvider.autoDispose<int>(
    (ref) => ref.watch(searchCacheProvider).count());

/// A track downloaded by an import, for the length check in «Rivedi».
final importedTrackProvider = StreamProvider.family<Track?, int>(
    (ref, id) => ref.watch(trackRepositoryProvider).watchById(id));

final playlistImportServiceProvider = Provider<PlaylistImportService>((ref) {
  final cached = ref.watch(cachedYoutubeProvider);
  final downloads = ref.read(downloadsProvider.notifier);
  final tracks = ref.watch(trackRepositoryProvider);
  final service = PlaylistImportService(
    imports: ref.watch(importRepositoryProvider),
    playlists: ref.watch(playlistRepositoryProvider),
    loadLibrary: tracks.liteEntries,
    youtube: cached,
    forgetSearches: (queries) => unawaited(cached.forget(queries)),
    thresholds: () {
      final s = ref.read(settingsProvider);
      return MatchThresholds(
              sure: s.importSureThreshold, review: s.importReviewThreshold)
          .clamped();
    },
    enqueue: (r, tag) => downloads.add(r, tag: tag),
    cancelDownloads: downloads.cancelWhere,
    settled: downloads.settled,
    trackIdForPath: tracks.idForPath,
    trackDurationMs: (id) async => (await tracks.getById(id))?.durationMs,
    pathForVideo: (id) async =>
        (await ref.read(downloadIndexProvider.future)).pathFor(id),
    applyTags: (trackId, row) async {
      final t = await tracks.getById(trackId);
      if (t == null) return;
      // The CSV tags are cleaner than the video title; grouping albums by the
      // first artist keeps a Spotify album in one piece.
      await ref.read(trackEditorProvider).save(
            t,
            TrackEdit(
              title: row.title,
              artist: row.artistLine,
              album: row.album,
              albumArtist: row.primaryArtist,
              year: t.year,
              trackNumber: t.trackNumber,
              genre: t.genre,
            ),
          );
    },
    youtubeEnabled: kEnableYoutube,
  );
  ref.onDispose(service.dispose);
  return service;
});

final importEventsProvider = StreamProvider<ImportEvent>(
  (ref) => ref.watch(playlistImportServiceProvider).events,
);

/// Imports still running or paused (Activity Center, playlist banner).
final unfinishedImportsProvider = StreamProvider<List<PlaylistImport>>(
  (ref) => ref.watch(importRepositoryProvider).watchUnfinished(),
);

/// Latest import attached to a playlist, in any state.
final playlistImportProvider =
    StreamProvider.family<PlaylistImport?, int>((ref, playlistId) =>
        ref.watch(importRepositoryProvider).watchForPlaylist(playlistId));

final importItemsProvider =
    StreamProvider.family<List<PlaylistImportItem>, int>((ref, importId) =>
        ref.watch(importRepositoryProvider).watchItems(importId));

/// What the Activity centre and the playlist banner show for one import.
class ImportProgress {
  const ImportProgress({
    required this.id,
    required this.playlistId,
    required this.name,
    required this.total,
    required this.done,
    required this.review,
    required this.missing,
    required this.paused,
    this.planned = 0,
  });

  factory ImportProgress.from(
    PlaylistImport imp,
    List<PlaylistImportItem> items,
  ) {
    var done = 0, review = 0, missing = 0, planned = 0;
    // Rows a sync took out of the source are no longer part of the import.
    final live = [
      for (final i in items)
        if (i.state != ImportItemStatus.removed) i,
    ];
    for (final i in live) {
      switch (i.state) {
        case ImportItemStatus.pending:
        case ImportItemStatus.queued:
        case ImportItemStatus.removed:
          break;
        case ImportItemStatus.review:
          review++;
          done++;
        case ImportItemStatus.notFound:
        case ImportItemStatus.failed:
          missing++;
          done++;
        case ImportItemStatus.planned:
          planned++;
          done++;
        case ImportItemStatus.downloaded:
        case ImportItemStatus.linked:
        case ImportItemStatus.skipped:
          done++;
      }
    }
    return ImportProgress(
      id: imp.id,
      playlistId: imp.playlistId,
      name: imp.sourceName,
      total: live.length,
      done: done,
      review: review,
      missing: missing,
      paused: imp.state == ImportStatus.paused,
      planned: planned,
    );
  }

  final int id, playlistId, total, done, review, missing, planned;
  final String name;
  final bool paused;

  double? get fraction => total == 0 ? null : done / total;
}

/// Imports still to finish, with counters (Activity centre).
final importProgressProvider = Provider<List<ImportProgress>>((ref) {
  final imports = ref.watch(unfinishedImportsProvider).value ?? const [];
  return [
    for (final i in imports)
      ImportProgress.from(
        i,
        ref.watch(importItemsProvider(i.id)).value ?? const [],
      ),
  ];
});

/// Counters of the latest import of a playlist (null = none).
final playlistImportProgressProvider =
    Provider.family<ImportProgress?, int>((ref, playlistId) {
      final imp = ref.watch(playlistImportProvider(playlistId)).value;
      if (imp == null || imp.state == ImportStatus.cancelled) return null;
      return ImportProgress.from(
        imp,
        ref.watch(importItemsProvider(imp.id)).value ?? const [],
      );
    });
