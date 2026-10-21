import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../providers/library_overlap_providers.dart';
import '../../../providers/ytm_catalog_providers.dart';
import '../../../services/online/youtube_service.dart';
import '../../../services/online/ytm_artist.dart';
import 'artist_page_sections.dart';
import 'catalog_error_view.dart';
import 'online_page_frame.dart';
import 'online_song_row.dart';

/// The long list behind «Mostra tutti» (up to 100 songs) of an artist.
class ArtistSongsScreen extends ConsumerWidget {
  const ArtistSongsScreen({
    super.key,
    required this.artist,
    required this.title,
    required this.link,
  });

  final YtmArtistRef artist;
  final String title;
  final YtmBrowseLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (browseId: link.browseId, params: link.params);
    final listKey = 'ytm-songs:${link.browseId}';
    final page = ref.watch(artistSongsProvider(key));
    final overlap = ref.watch(localOverlapProvider(artist.name));
    final data = page.value;
    final songs = data?.value ?? const <YtResult>[];
    return OnlinePageFrame(
      title: '${artist.name} · $title',
      selectionKey: listKey,
      pickable: songs,
      onRefresh: () async {
        try {
          await ref
              .read(ytmCatalogProvider)
              .songs(link, ref.read(ytmLanguageProvider), refresh: true);
        } on Object catch (e) {
          AppLog.w('song list: refresh failed ($e)');
        }
        ref.invalidate(artistSongsProvider(key));
      },
      slivers: [
        if (data != null && data.stale)
          SliverToBoxAdapter(child: OfflineNotice(fetchedAt: data.fetchedAt)),
        if (data != null)
          SliverFixedExtentList.builder(
            itemExtent: 72,
            itemCount: songs.length,
            itemBuilder: (_, i) => OnlineSongTile(
              result: songs[i],
              index: i,
              selectionKey: listKey,
              ownedLocally: overlap.owns(songs[i]),
            ),
          )
        else if (page.hasError)
          SliverToBoxAdapter(
            child: CatalogErrorView(
              error: page.error!,
              onRetry: () => ref.invalidate(artistSongsProvider(key)),
            ),
          )
        else
          const SliverToBoxAdapter(child: PageSkeleton(rows: 8)),
      ],
    );
  }
}
