import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../core/paths.dart';
import '../data/db/app_database.dart';
import '../data/repositories/library_queries.dart';
import '../data/repositories/track_repository.dart';
import '../services/covers/cover_store.dart';
import '../services/scanner/library_scanner.dart';
import '../services/tags/audio_metadata_tag_reader.dart';
import '../services/tags/tag_reader.dart';
import 'database_providers.dart';

final tagReaderProvider =
    Provider<TagReader>((ref) => const AudioMetadataTagReader());

final coversDirProvider = FutureProvider<Directory>(
    (ref) async => Directory(await coversDir()));

final coverStoreProvider = Provider<CoverStore>((ref) {
  final dir = ref.watch(coversDirProvider).requireValue;
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
  @override
  TrackQuery build() => const TrackQuery();

  void update(TrackQuery Function(TrackQuery) change) =>
      state = change(state);
}

final trackQueryProvider =
    NotifierProvider<TrackQueryNotifier, TrackQuery>(TrackQueryNotifier.new);

final tracksProvider = StreamProvider<List<Track>>((ref) {
  final q = ref.watch(trackQueryProvider);
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
      await ref.read(coversDirProvider.future);
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
    } on Object catch (e, st) {
      AppLog.e('scan failed', e, st);
      state = ScanState(error: '$e');
    }
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

final artistAlbumsProvider = StreamProvider.family<List<AlbumSummary>, String>(
    (ref, key) => ref.watch(libraryQueriesProvider).watchArtistAlbums(key));
