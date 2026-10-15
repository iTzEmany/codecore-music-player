import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/database_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/nav_providers.dart';
import '../screens/library/favorites_screen.dart';
import '../screens/playlists/playlist_detail_screen.dart';
import '../screens/playlists/playlist_dialogs.dart';
import '../theme/tokens.dart';
import '../widgets/playlist_cover.dart';
import 'shell_nav.dart';

/// Left column of the desktop layout: Home, Search, the library with the
/// pinned Favourites and every playlist. Icons only when narrow.
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key, required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final index = ref.watch(navIndexProvider);
    final keys = ref.watch(tabNavigatorKeysProvider);
    final lists = ref.watch(playlistsProvider).value ?? const [];
    final favoriteCount = ref.watch(
      tracksProvider(true).select((t) => t.value?.length ?? 0),
    );
    void select(NavTab t) {
      if (index == t.index) {
        keys[t.index].currentState?.popUntil((r) => r.isFirst);
      } else {
        ref.read(navIndexProvider.notifier).set(t.index);
      }
    }

    Widget item(
      IconData icon,
      String label,
      bool selected,
      VoidCallback onTap, {
      Widget? trailing,
    }) {
      final color = selected ? cc.text : cc.textMuted;
      final child = collapsed
          ? Center(child: Icon(icon, color: color))
          : Row(
              children: [
                const SizedBox(width: 16),
                Icon(icon, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: color),
                  ),
                ),
                ?trailing,
              ],
            );
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(height: 48, child: child),
        ),
      );
    }

    Widget rowWithCover(
      Widget cover,
      String title,
      String subtitle,
      VoidCallback onTap,
    ) {
      final theme = Theme.of(context).textTheme;
      return Tooltip(
        message: title,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                SizedBox(width: collapsed ? 16 : 12),
                cover,
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyLarge,
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: collapsed ? CcDims.sidebarCollapsedWidth : CcDims.sidebarWidth,
      child: Material(
        color: cc.bg,
        child: Column(
          children: [
            const SizedBox(height: 12),
            item(
              index == 0 ? Icons.home_rounded : Icons.home_outlined,
              l.navHome,
              index == NavTab.home.index,
              () => select(NavTab.home),
            ),
            item(
              Icons.search_rounded,
              l.navSearch,
              index == NavTab.search.index,
              () => select(NavTab.search),
            ),
            const Divider(height: 16),
            item(
              index == NavTab.library.index
                  ? Icons.library_music_rounded
                  : Icons.library_music_outlined,
              l.yourLibrary,
              index == NavTab.library.index,
              () => select(NavTab.library),
              trailing: IconButton(
                tooltip: l.newPlaylist,
                icon: const Icon(Icons.add_rounded),
                onPressed: () async {
                  final name = await askPlaylistName(context);
                  if (name == null) return;
                  await ref.read(playlistRepositoryProvider).create(name);
                },
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  rowWithCover(
                    const PlaylistCover(size: 40, favorites: true),
                    l.navFavorites,
                    l.playlistCountLabel(favoriteCount),
                    () => ShellNav.openInLibrary(
                      context,
                      ref,
                      const FavoritesScreen(),
                    ),
                  ),
                  for (final p in lists)
                    rowWithCover(
                      PlaylistCover(
                        size: 40,
                        coverKeys: playlistCoverKeys(p.playlist.coverKey, [
                          p.autoCoverKey,
                        ]),
                      ),
                      p.playlist.name,
                      l.playlistCountLabel(p.trackCount),
                      () => ShellNav.openInLibrary(
                        context,
                        ref,
                        PlaylistDetailScreen(playlist: p.playlist),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
