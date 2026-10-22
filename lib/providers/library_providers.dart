import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/app_log.dart';
import '../data/db/app_database.dart';
import '../data/repositories/library_queries.dart';
import '../data/repositories/smart_search.dart';
import '../data/repositories/track_repository.dart';
import '../services/covers/cover_store.dart';
import '../services/covers/cover_thumbnails.dart';
import '../services/scanner/library_scanner.dart';
import '../services/tags/audio_metadata_tag_reader.dart';
import '../services/tags/metadata_god_tag_writer.dart';
import '../services/tags/safe_tag_writer.dart';
import '../services/tags/tag_backups.dart';
import '../services/tags/tag_reader.dart';
import '../services/tags/tag_writer.dart';
import '../services/library/rules/rule_parser.dart';
import '../services/library/track_editor.dart';
import '../services/library/track_file_sync.dart';
import '../core/paths.dart';
import 'database_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';

final tagReaderProvider = Provider<TagReader>(
  (ref) => const AudioMetadataTagReader(),
);

/// Resolved once in `main` (and overridden in tests): synchronous everywhere.
final coversDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('coversDirProvider not overridden'),
);

final coverStoreProvider = Provider<CoverStore>((ref) {
  final dir = ref.watch(coversDirProvider);
  return CoverStore(dir, thumbnails: encodeCoverThumbnail);
});

final libraryScannerProvider = Provider<LibraryScanner>(
  (ref) => LibraryScanner(
    ref.watch(tagReaderProvider),
    ref.watch(trackRepositoryProvider),
    ref.watch(coverStoreProvider),
  ),
);

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

  void update(TrackQuery Function(TrackQuery) change) => state = change(state);
}

/// Argument: favoritesOnly. Each list (all tracks / favourites) keeps its own
/// search text and sort order.
final trackQueryProvider =
    NotifierProvider.family<TrackQueryNotifier, TrackQuery, bool>(
      TrackQueryNotifier.new,
    );

final tracksProvider = StreamProvider.family<List<Track>, bool>((ref, fav) {
  final q = ref.watch(trackQueryProvider(fav));
  return ref
      .watch(trackRepositoryProvider)
      .watchTracks(query: q.text, sort: q.sort, favoritesOnly: q.favoritesOnly);
});

final foldersProvider = StreamProvider<List<Folder>>(
  (ref) => ref.watch(folderRepositoryProvider).watchAll(),
);

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
    ref
        .read(enrichJobProvider.notifier)
        .start(
          fresh,
          includeLyrics: s.autoLyrics,
          includeMetadata: s.autoEnrich,
        );
  }
}

final scanStateProvider = NotifierProvider<ScanNotifier, ScanState>(
  ScanNotifier.new,
);

final libraryQueriesProvider = Provider<LibraryQueries>(
  (ref) => LibraryQueries(ref.watch(databaseProvider)),
);

class AlbumSortNotifier extends Notifier<AlbumSort> {
  @override
  AlbumSort build() => AlbumSort.title;

  void set(AlbumSort s) => state = s;
}

final albumSortProvider = NotifierProvider<AlbumSortNotifier, AlbumSort>(
  AlbumSortNotifier.new,
);

final albumsProvider = StreamProvider<List<AlbumSummary>>(
  (ref) => ref
      .watch(libraryQueriesProvider)
      .watchAlbums(sort: ref.watch(albumSortProvider)),
);

final artistsProvider = StreamProvider<List<ArtistSummary>>(
  (ref) => ref.watch(libraryQueriesProvider).watchArtists(),
);

final albumTracksProvider = StreamProvider.family<List<Track>, String>(
  (ref, albumKey) =>
      ref.watch(libraryQueriesProvider).watchAlbumTracks(albumKey),
);

final genresProvider = StreamProvider<List<GenreSummary>>(
  (ref) => ref.watch(libraryQueriesProvider).watchGenres(),
);

final genreTracksProvider = StreamProvider.family<List<Track>, String>(
  (ref, genre) => ref.watch(libraryQueriesProvider).watchGenreTracks(genre),
);

/// What the Library search asks for: the text and the two quick filters.
class SearchQuery {
  const SearchQuery(this.text, {this.favorites = false, this.recent = false});

  final String text;
  final bool favorites, recent;

  bool get quick => favorites || recent;

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.text == text &&
      other.favorites == favorites &&
      other.recent == recent;

  @override
  int get hashCode => Object.hash(text, favorites, recent);
}

/// Every visible track with its tags, normalised once per change of the
/// library (not at every key typed).
final _indexTracksProvider = StreamProvider<List<Track>>(
  (ref) => ref.watch(trackRepositoryProvider).watchTracks(),
);

final _indexTagsProvider = StreamProvider<Map<int, List<String>>>(
  (ref) => ref.watch(tagRepositoryProvider).watchNamesByTrack(),
);

final searchIndexProvider = Provider<AsyncValue<SearchIndex>>((ref) {
  final tracks = ref.watch(_indexTracksProvider);
  final tags = ref.watch(_indexTagsProvider);
  if (tracks.hasError) return AsyncError(tracks.error!, tracks.stackTrace!);
  final list = tracks.value;
  if (list == null) return const AsyncLoading();
  return AsyncData(SearchIndex(list, tags.value ?? const {}));
});

// autoDispose (here and below): one entry per text typed, and an entry left
// paused would keep its last result, rows of an older read of the library,
// for the whole session.
final _ruleTracksProvider = StreamProvider.autoDispose.family<List<Track>, String>(
  (ref, text) => ref.watch(trackRepositoryProvider).watchByRules(parseRules(text).expr),
);

/// Tracks matching a search: free words look in title, artist, album, genre,
/// year and tags together, best match first. Typed operators
/// (`artista:x anno:1990..1999 -live`) still run as rules in SQL, silently.
final searchTracksProvider = Provider.autoDispose.family<AsyncValue<List<Track>>, SearchQuery>((
  ref,
  q,
) {
  final now = DateTime.now().millisecondsSinceEpoch;
  if (hasOperators(q.text)) {
    return ref.watch(_ruleTracksProvider(q.text)).whenData(
      (l) => applyQuickFilters(l, favorites: q.favorites, recent: q.recent, nowMs: now),
    );
  }
  return ref.watch(searchIndexProvider).whenData(
    (i) => smartSearch(i, q.text, favorites: q.favorites, recent: q.recent, nowMs: now),
  );
});

final topTracksProvider = StreamProvider<List<Track>>(
  (ref) => ref.watch(libraryQueriesProvider).watchTopTracks(),
);

final resumableTracksProvider = StreamProvider.autoDispose<List<Track>>(
  (ref) => ref.watch(trackRepositoryProvider).watchResumable(),
);

final artistTracksProvider = StreamProvider.family<List<Track>, String>(
  (ref, key) => ref.watch(libraryQueriesProvider).watchArtistTracks(key),
);

final artistAlbumsProvider = StreamProvider.family<List<AlbumSummary>, String>(
  (ref, key) => ref.watch(libraryQueriesProvider).watchArtistAlbums(key),
);

/// The only door to writing tags into files; tests override it.
final tagWriterProvider = Provider<TagWriter>((ref) => MetadataGodTagWriter());

final tagBackupStoreProvider = FutureProvider<TagBackupStore>(
  (ref) async =>
      TagBackupStore(Directory(p.join(await appSupportDir(), 'tag_backups'))),
);

final safeTagWriterProvider = FutureProvider<SafeTagWriter>((ref) async {
  return SafeTagWriter(
    writer: ref.watch(tagWriterProvider),
    reader: ref.watch(tagReaderProvider),
    workDir: Directory(p.join(await appSupportDir(), 'tagwork')),
    backups: await ref.watch(tagBackupStoreProvider.future),
  );
});

final trackEditorProvider = Provider<TrackEditor>((ref) {
  final db = ref.watch(databaseProvider);
  return TrackEditor(
    db,
    ref.watch(tagReaderProvider),
    files: TrackFileSync(db, () => ref.read(safeTagWriterProvider.future)),
    fileWritesEnabled: () {
      final s = ref.read(settingsProvider);
      return s.writeTagsToFiles && s.tagsAlsoInFile;
    },
  );
});

final missingTracksProvider = StreamProvider<List<Track>>(
  (ref) => ref.watch(trackRepositoryProvider).watchMissing(),
);

class PermissionDeniedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final permissionDeniedProvider =
    NotifierProvider<PermissionDeniedNotifier, bool>(
      PermissionDeniedNotifier.new,
    );
