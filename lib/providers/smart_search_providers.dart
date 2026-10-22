import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online/query_match.dart' show libraryArtistKey;
import '../services/online/smart_search.dart';
import '../services/online/source_cooldown.dart';
import 'library_providers.dart' show artistsProvider;
import 'youtube_providers.dart';
import 'ytm_catalog_providers.dart';

/// The pauses of the sources that said «too many requests», kept for the session.
final sourceCooldownProvider = Provider<SourceCooldown>((ref) => SourceCooldown());

/// Keys of the artists in the library, rebuilt only when the library's artists
/// change; the online search favours their results for a phrase with no artist.
final libraryArtistKeysProvider = Provider<Set<String>>((ref) {
  final artists = ref.watch(artistsProvider).value ?? const [];
  final keys = {for (final a in artists) libraryArtistKey(a.name ?? '')};
  return keys..remove('');
});

/// The engine; holds the 10-minute copy of recent searches.
final smartSearchEngineProvider = Provider<SmartSearch>((ref) => SmartSearch(
      youtube: ref.watch(youtubeServiceProvider),
      catalog: ref.watch(ytmCatalogProvider),
      cooldown: ref.watch(sourceCooldownProvider),
      libraryArtists: () => ref.read(libraryArtistKeysProvider),
    ));

/// One online search. [serial] makes a new submit of the same text a new
/// request (the page counts them); with `refresh` the saved copy is skipped.
/// Leaving a request (the page asks for another one) disposes it, which
/// cancels the stream and so drops the answers still on their way.
typedef SmartSearchRequest = ({String query, bool refresh, int serial});

final smartSearchProvider = StreamProvider.autoDispose
    .family<SmartSearchState, SmartSearchRequest>((ref, request) {
  return ref.watch(smartSearchEngineProvider).run(
        request.query,
        ref.read(ytmLanguageProvider),
        refresh: request.refresh,
      );
});
