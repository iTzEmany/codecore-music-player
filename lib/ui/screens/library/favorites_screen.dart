import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/track_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/collection_header.dart';
import '../../widgets/error_state.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/track_row.dart';
import 'album_detail_screen.dart' show tracksAndMinutes;

/// The favourites as a collection page (pinned in the Library).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  String _sortLabel(BuildContext context, SortOption o) {
    final l = context.l10n;
    return switch (o) {
      SortOption.defaultOrder => l.sortDefault,
      SortOption.title => l.sortTitle,
      SortOption.artist => l.sortArtist,
      SortOption.album => l.sortAlbum,
      SortOption.year => l.sortYear,
      SortOption.addedAt => l.sortAdded,
      SortOption.duration => l.sortDuration,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final tracks = ref.watch(tracksProvider(true));
    final query = ref.watch(trackQueryProvider(true));
    final compact = ref.watch(settingsProvider).compactMode;
    final ctrl = ref.read(playerControllerProvider);
    final list = tracks.value ?? const [];
    const playCtx = PlayContext(PlayContextKind.favorites);
    final durationMs = list.fold<int>(0, (a, t) => a + t.durationMs);
    final extent = trackRowExtentOf(context, compact);
    return CollectionScaffold(
      title: l.navFavorites,
      name: l.navFavorites,
      cover: (s) =>
          PlaylistCover(size: s, favorites: true, radius: CcDims.rGrid),
      meta:
          '${l.kindPlaylist} · ${tracksAndMinutes(context, list.length, durationMs)}',
      onPlay: list.isEmpty
          ? null
          : () => ctrl.playFromList(list, 0, context: playCtx),
      onShuffle: list.isEmpty
          ? null
          : () async {
              await ctrl.setShuffle(true);
              await ctrl.playFromList(list, 0, context: playCtx);
            },
      menu: PopupMenuButton<SortOption>(
        tooltip: l.sortBy,
        icon: const Icon(Icons.sort_rounded),
        initialValue: query.sort,
        onSelected: (s) => ref
            .read(trackQueryProvider(true).notifier)
            .update((q) => q.copyWith(sort: s)),
        itemBuilder: (_) => [
          for (final o in SortOption.values)
            PopupMenuItem(value: o, child: Text(_sortLabel(context, o))),
        ],
      ),
      slivers: [
        if (tracks.hasError)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 240,
              child: loadErrorState(
                context,
                tracks.error!,
                StackTrace.current,
                onRetry: () => ref.invalidate(tracksProvider(true)),
              ),
            ),
          )
        else if (tracks.hasValue && list.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 56,
                    color: cc.textFaint,
                  ),
                  const SizedBox(height: 12),
                  Text(l.noFavorites, textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => SizedBox(
              height: extent,
              child: LiveTrackRow(
                track: list[i],
                compact: compact,
                onTap: () => ctrl.playFromList(list, i, context: playCtx),
              ),
            ),
          ),
      ],
    );
  }
}
