import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../data/db/app_database.dart';
import '../data/repositories/library_queries.dart';
import '../data/repositories/track_repository.dart';
import '../services/covers/cover_store.dart';
import '../services/scanner/library_scanner.dart';
import '../services/tags/audio_metadata_tag_reader.dart';
import '../services/tags/tag_reader.dart';
import '../services/library/track_editor.dart';
import 'database_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';

final tagReaderProvider =
    Provider<TagReader>((ref) => const AudioMetadataTagReader());

/// Resolved once in `main` (and overridden in tests): synchronous everywhere.
final coversDirProvider = Provider<Directory>(
    (ref) => throw UnimplementedError('coversDirProvider not overridden'));

final coverStoreProvider = Provider<CoverStore>((ref) {
  final dir = ref.watch(coversDirProvider);
  return CoverStore(dir);
});

final libraryScannerProvider = Provider<LibraryScanner>((ref) => LibraryScanner(
      ref.watch(tagReaderProvider),
      ref.watch(trackRepositoryProvider),
      ref.watch(coverStoreProvider),
    ));

class TrackQuery {
  const TrackQuery({
    this.text = '',
    this.sort = SortOption.defaultOrder,
    this.favoritesOnly = false,
  });

  final String text;
  final SortOption sort;
  final bool favoritesOnly;

  TrackQuery copyWith({String? text, SortOption? sort, bool? favoritesOnly}) =>
      TrackQuery(
        text: text ?? this.text,
        sort: sort ?? this.sort,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      );
}

class TrackQueryNotifier extends Notifier<TrackQuery> {
  TrackQueryNotifier(this.favoritesOnly);

  final bool favoritesOnly;

  @override
  TrackQuery build() => TrackQuery(favoritesOnly: favoritesOnly);

  void update(TrackQuery Function(TrackQuery) change) =>
      state = change(state);
}

/// Argument: favoritesOnly. Each list (all tracks / favourites) keeps its own
/// search text and sort order.
final trackQueryProvider =
    NotifierProvider.family<TrackQueryNotifier, TrackQuery, bool>(
        TrackQueryNotifier.new);

final tracksProvider = StreamProvider.family<List<Track>, bool>((ref, fav) {
  final q = ref.watch(trackQueryProvider(fav));
  return ref.watch(trackRepositoryProvider).watchTracks(
        query: q.text,
        sort: q.sort,
        favoritesOnly: q.favoritesOnly,
      );
});

final foldersProvider = StreamProvider<List<Folder>>(
    (ref) => ref.watch(folderRepositoryProvider).watchAll());

class ScanState {
  const ScanState({this.running = false, this.progress, this.error});

  final bool running;
  final ScanProgress? progress;
  final String? error;
}

class ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();

  Future<void> scanAll() async {
    if (state.running) return;
    state = const ScanState(running: true);
    try {
      final folders = await ref.read(folderRepositoryProvider).getAll();
      final scanner = ref.read(libraryScannerProvider);
      String? error;
      for (final folder in folders) {
        await for (final p in scanner.scan(folder)) {
          if (p.failed) error = p.error;
          state = ScanState(running: true, progress: p, error: error);
        }
      }
      state = ScanState(progress: state.progress, error: error);
      await _autoEnrich();
    } on Object catch (e, st) {
      AppLog.e('scan failed', e, st);
      state = ScanState(error: '$e');
    }
  }

  Future<void> _autoEnrich() async {
    final s = ref.read(settingsProvider);
    if (!s.autoEnrich && !s.autoLyrics) return;
    final fresh = (await ref.read(trackRepositoryProvider).watchTracks().first)
        .where((t) => t.enrichStatus == 0)
        .map((t) => t.id)
        .toList();
    ref.read(enrichJobProvider.notifier).start(fresh,
        includeLyrics: s.autoLyrics, includeMetadata: s.autoEnrich);
  }
}

final scanStateProvider =
    NotifierProvider<ScanNotifier, ScanState>(ScanNotifier.new);

final libraryQueriesProvider =
    Provider<LibraryQueries>((ref) => LibraryQueries(ref.watch(databaseProvider)));

class AlbumSortNotifier extends Notifier<AlbumSort> {
  @override
  AlbumSort build() => AlbumSort.title;

  void set(AlbumSort s) => state = s;
}

final albumSortProvider =
    NotifierProvider<AlbumSortNotifier, AlbumSort>(AlbumSortNotifier.new);

final albumsProvider = StreamProvider<List<AlbumSummary>>((ref) => ref
    .watch(libraryQueriesProvider)
    .watchAlbums(sort: ref.watch(albumSortProvider)));

final artistsProvider = StreamProvider<List<ArtistSummary>>(
    (ref) => ref.watch(libraryQueriesProvider).watchArtists());

final albumTracksProvider = StreamProvider.family<List<Track>, String>(
    (ref, albumKey) =>
        ref.watch(libraryQueriesProvider).watchAlbumTracks(albumKey));

final artistTracksProvider = StreamProvider.family<List<Track>, String>(
    (ref, key) => ref.watch(libraryQueriesProvider).watchArtistTracks(key));

final artistAlbumsProvider = StreamProvider.family<List<AlbumSummary>, String>(
    (ref, key) => ref.watch(libraryQueriesProvider).watchArtistAlbums(key));

final trackEditorProvider = Provider<TrackEditor>((ref) =>
    TrackEditor(ref.watch(databaseProvider), ref.watch(tagReaderProvider)));

final missingTracksProvider = StreamProvider<List<Track>>(
    (ref) => ref.watch(trackRepositoryProvider).watchMissing());

class PermissionDeniedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final permissionDeniedProvider =
    NotifierProvider<PermissionDeniedNotifier, bool>(
        PermissionDeniedNotifier.new);
