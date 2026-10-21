import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../providers/ytm_catalog_providers.dart';
import '../../../services/online/ytm_artist.dart';
import '../../shell/shell_nav.dart';
import 'artist_page_sections.dart';
import 'catalog_error_view.dart';
import 'online_album_screen.dart';
import 'online_page_frame.dart';

/// Every release behind a carousel's «Mostra tutto»: a grid of covers.
class DiscographyScreen extends ConsumerWidget {
  const DiscographyScreen({
    super.key,
    required this.artist,
    required this.title,
    required this.link,
  });

  final YtmArtistRef artist;
  final String title;
  final YtmBrowseLink link;

  static const _cell = 180.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (browseId: link.browseId, params: link.params);
    final page = ref.watch(discographyProvider(key));
    final data = page.value;
    final extent = _cell + 8 + MediaQuery.textScalerOf(context).scale(62);
    return OnlinePageFrame(
      title: '${artist.name} · $title',
      onRefresh: () async {
        try {
          await ref
              .read(ytmCatalogProvider)
              .discography(link, ref.read(ytmLanguageProvider), refresh: true);
        } on Object catch (e) {
          AppLog.w('discography: refresh failed ($e)');
        }
        ref.invalidate(discographyProvider(key));
      },
      slivers: [
        if (data != null && data.stale)
          SliverToBoxAdapter(child: OfflineNotice(fetchedAt: data.fetchedAt)),
        if (data != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: _cell,
                mainAxisExtent: extent,
              ),
              itemCount: data.value.length,
              itemBuilder: (_, i) => LayoutBuilder(
                builder: (_, box) => ReleaseTile(
                  release: data.value[i],
                  size: box.maxWidth - 12,
                  onTap: (r) => ShellNav.open<void>(
                      context, OnlineAlbumScreen(browseId: r.browseId, release: r)),
                ),
              ),
            ),
          )
        else if (page.hasError)
          SliverToBoxAdapter(
            child: CatalogErrorView(
              error: page.error!,
              onRetry: () => ref.invalidate(discographyProvider(key)),
            ),
          )
        else
          const SliverToBoxAdapter(child: PageSkeleton(rows: 6)),
      ],
    );
  }
}
