import 'package:flutter/material.dart';
import '../widgets/create_flows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/database_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/nav_providers.dart';
import '../../providers/playlist_ops.dart';
import '../../providers/track_ops.dart';
import '../screens/import/import_flow.dart';
import '../screens/library/favorites_screen.dart';
import '../screens/playlists/playlist_detail_screen.dart';
import '../screens/playlists/playlist_dialogs.dart';
import '../screens/smart/smart_playlist_editor.dart';
import '../theme/tokens.dart';
import '../widgets/playlist_cover.dart';
import '../widgets/track_drag.dart';
import 'shell_nav.dart';
import '../widgets/show_msg.dart';

/// Left column of the desktop layout: Home, Search, the library with the
/// pinned Favourites and every playlist, then Memoria. Icons only when narrow.
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
      // The library entry is a destination, not a tab restore: a page left
      // open in that tab must not hide the library itself.
      if (index == t.index || t == NavTab.library) {
        keys[t.index].currentState?.popUntil((r) => r.isFirst);
      }
      if (index != t.index) ref.read(navIndexProvider.notifier).set(t.index);
    }

    Widget item(
      IconData icon,
      String label,
      bool selected,
      VoidCallback onTap, {
      Widget? trailing,
    }) {
      final color = selected ? cc.text : cc.textMuted;
      // Static accent dot at the icon's top right (a list, not a row of tabs).
      final glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: color),
          if (selected)
            Positioned(
              top: -1,
              right: -3,
              child: Container(
                key: const Key('sidebar-dot'),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: cc.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
      final child = collapsed
          ? Center(child: glyph)
          : Row(
              children: [
                const SizedBox(width: 16),
                glyph,
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

    void say(String text) => showMsg(context, text);

    Future<void> dropOnPlaylist(int id, String name, List<int> ids) async {
      final added = await ref.read(playlistOpsProvider).addTracks(id, ids);
      say(addedToPlaylistText(l, total: ids.length, added: added, name: name));
    }

    Future<void> dropOnFavorites(List<int> ids) async {
      say(l.favoritesAdded(await ref.read(trackOpsProvider).addFavorites(ids)));
    }

    Widget rowWithCover(
      Widget cover,
      String title,
      String subtitle,
      VoidCallback onTap, {
      required void Function(List<int> ids) onDrop,
    }) {
      final theme = Theme.of(context).textTheme;
      return TrackDropTarget(
        onDrop: onDrop,
        child: Tooltip(
          message: title,
          child: InkWell(
            onTap: onTap,
            // Grows with the text size: two lines at 150 % no longer fit in 56.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
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
              trailing: PopupMenuButton<String>(
                tooltip: l.newPlaylist,
                icon: const Icon(Icons.add_rounded),
                onSelected: (v) async {
                  if (v == 'csv') {
                    startCsvImport(context, ref);
                    return;
                  }
                  if (v == 'smart') {
                    ShellNav.openInLibrary(
                      context,
                      ref,
                      const SmartPlaylistEditor(),
                    );
                    return;
                  }
                  await createPlaylistFlow(context, ref);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'new', child: Text(l.newPlaylist)),
                  PopupMenuItem(value: 'smart', child: Text(l.smartPlaylistNew)),
                  PopupMenuItem(value: 'csv', child: Text(l.csvImportMenu)),
                ],
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
                    onDrop: dropOnFavorites,
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
                      onDrop: (ids) =>
                          dropOnPlaylist(p.playlist.id, p.playlist.name, ids),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            item(
              index == NavTab.memory.index
                  ? Icons.storage_rounded
                  : Icons.storage_outlined,
              l.navMemory,
              index == NavTab.memory.index,
              () => select(NavTab.memory),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
