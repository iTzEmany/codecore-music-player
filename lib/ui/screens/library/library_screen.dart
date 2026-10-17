import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/repositories/library_entries.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/nav_providers.dart';
import '../../../providers/podcast_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/smart_playlist_providers.dart';
import '../../../providers/tag_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/activity_button.dart';
import '../../widgets/artist_avatar.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/smart_cover.dart';
import '../devices/devices_sheet.dart';
import '../import/import_flow.dart';
import '../playlists/playlist_detail_screen.dart';
import '../podcast/podcasts_screen.dart';
import '../playlists/playlist_dialogs.dart';
import 'album_detail_screen.dart';
import 'all_tracks_screen.dart';
import 'artist_screen.dart';
import 'favorites_screen.dart';
import '../history/history_screen.dart';
import '../smart/smart_playlist_editor.dart';
import '../smart/smart_playlist_screen.dart';
import '../stats/stats_screen.dart';
import '../tags/tags_screen.dart';
import 'folders_sheet.dart';
import 'scan_status.dart';

/// Playlists, albums and artists in one place, with Favourites and
/// «Tutti i brani» pinned on top.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryKind? _kind;

  void _setSettings({LibrarySort? sort, bool? grid}) => ref
      .read(settingsProvider.notifier)
      .update((s) => s.copyWith(librarySort: sort?.name, libraryGrid: grid));

  void _open(LibraryEntry e) {
    final Widget page = switch (e.kind) {
      LibraryKind.playlist when e.smart != null => SmartPlaylistScreen(
        id: e.smart!.id,
      ),
      LibraryKind.playlist => PlaylistDetailScreen(
        playlist: e.playlist!.playlist,
      ),
      LibraryKind.album => AlbumDetailScreen(album: e.album!),
      LibraryKind.artist => ArtistDetailScreen(artist: e.artistSummary!),
    };
    ShellNav.open<void>(context, page);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final sort = LibrarySort.values.firstWhere(
      (s) => s.name == settings.librarySort,
      orElse: () => LibrarySort.recent,
    );
    final playlists = ref.watch(playlistsProvider);
    final smart = ref.watch(smartPlaylistsProvider).value ?? const [];
    final albums = ref.watch(albumsProvider);
    final artists = ref.watch(artistsProvider);
    final folders = ref.watch(foldersProvider).value;
    final favCount = ref.watch(
      tracksProvider(true).select((t) => t.value?.length ?? 0),
    );
    final trackCount = ref.watch(
      tracksProvider(false).select((t) => t.value?.length ?? 0),
    );
    final tagCount = ref.watch(tagsProvider.select((t) => t.value?.length ?? 0));
    final podcastCount = ref.watch(podcastsProvider.select((p) => p.value?.length ?? 0));
    final theme = Theme.of(context).textTheme;
    final denied = ref.watch(permissionDeniedProvider);

    Widget body;
    final error = playlists.error ?? albums.error ?? artists.error;
    if (denied) {
      body = EmptyState(
        icon: Icons.lock,
        message: l.permissionExplain,
        actionLabel: l.openSettings,
        onAction: openAppSettings,
      );
    } else if (error != null) {
      body = loadErrorState(
        context,
        error,
        StackTrace.current,
        onRetry: () {
          ref.invalidate(playlistsProvider);
          ref.invalidate(albumsProvider);
          ref.invalidate(artistsProvider);
        },
      );
    } else if (!playlists.hasValue || !albums.hasValue || !artists.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else if (trackCount == 0 && folders != null && folders.isEmpty) {
      body = EmptyState(
        icon: Icons.library_music,
        message: l.addMusicFolder,
        actionLabel: l.addFolder,
        onAction: () => addFolderAndScan(ref),
        secondaryLabel: l.useDefaultFolder,
        onSecondary: () => addDefaultFolderAndScan(ref),
      );
    } else {
      final entries = buildLibraryEntries(
        playlists: playlists.value!,
        albums: albums.value!,
        artists: artists.value!,
        smart: smart,
        kind: _kind,
        sort: sort,
      );
      final pinned = [
        _Pinned(
          favorites: true,
          title: l.navFavorites,
          subtitle: l.playlistCountLabel(favCount),
          onTap: () => ShellNav.open<void>(context, const FavoritesScreen()),
        ),
        _Pinned(
          title: l.allTracks,
          subtitle: l.tracksCount(trackCount),
          onTap: () => ShellNav.open<void>(context, const AllTracksScreen()),
        ),
        _Pinned(
          icon: Icons.podcasts_rounded,
          title: l.podcastsTitle,
          subtitle: l.podcastsSubtitle(podcastCount),
          onTap: () => ShellNav.open<void>(context, const PodcastsScreen()),
        ),
        _Pinned(
          icon: Icons.history_rounded,
          title: l.historyTitle,
          subtitle: l.historySubtitle,
          onTap: () => ShellNav.open<void>(context, const HistoryScreen()),
        ),
        _Pinned(
          icon: Icons.label_outline_rounded,
          title: l.tagsTitle,
          subtitle: l.tagsCount(tagCount),
          onTap: () => ShellNav.open<void>(context, const TagsScreen()),
        ),
        _Pinned(
          icon: Icons.bar_chart_rounded,
          title: l.statsTitle,
          subtitle: l.statsSubtitle,
          onTap: () => ShellNav.open<void>(context, const StatsScreen()),
        ),
      ];
      body = settings.libraryGrid
          ? _LibraryGrid(pinned: pinned, entries: entries, onOpen: _open)
          : _LibraryList(pinned: pinned, entries: entries, onOpen: _open);
    }

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(CcDims.margin, 12, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.navLibrary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.headlineSmall,
                  ),
                ),
                const ActivityButton(),
                IconButton(
                  tooltip: l.navSearch,
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => ref
                      .read(navIndexProvider.notifier)
                      .set(NavTab.search.index),
                ),
                PopupMenuButton<String>(
                  tooltip: l.newPlaylist,
                  icon: const Icon(Icons.add_rounded),
                  onSelected: (v) async {
                    if (v == 'csv') {
                      startCsvImport(context, ref);
                      return;
                    }
                    if (v == 'smart') {
                      await ShellNav.open<bool>(
                        context,
                        const SmartPlaylistEditor(),
                      );
                      return;
                    }
                    final name = await askPlaylistName(context);
                    if (name == null) return;
                    await ref.read(playlistRepositoryProvider).create(name);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'new',
                      child: Text(l.newPlaylist),
                    ),
                    PopupMenuItem(
                      value: 'smart',
                      child: Text(l.smartPlaylistNew),
                    ),
                    PopupMenuItem(
                      value: 'csv',
                      child: Text(l.csvImportMenu),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: l.moreActions,
                  onSelected: (v) {
                    switch (v) {
                      case 'folders':
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => const FoldersSheet(),
                        );
                      case 'scan':
                        scanWithPermission(ref);
                      case 'share':
                        DevicesSheet.show(context);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'folders', child: Text(l.folders)),
                    PopupMenuItem(value: 'scan', child: Text(l.refreshLibrary)),
                    PopupMenuItem(value: 'share', child: Text(l.shareTitle)),
                  ],
                ),
              ],
            ),
          ),
          const ScanStatus(),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
              children: [
                chip(
                  l.navPlaylists,
                  _kind == LibraryKind.playlist,
                  () => setState(
                    () => _kind = _kind == LibraryKind.playlist
                        ? null
                        : LibraryKind.playlist,
                  ),
                ),
                chip(
                  l.albums,
                  _kind == LibraryKind.album,
                  () => setState(
                    () => _kind = _kind == LibraryKind.album
                        ? null
                        : LibraryKind.album,
                  ),
                ),
                chip(
                  l.artists,
                  _kind == LibraryKind.artist,
                  () => setState(
                    () => _kind = _kind == LibraryKind.artist
                        ? null
                        : LibraryKind.artist,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: CcDims.margin),
                    children: [
                      chip(
                        l.sortRecent,
                        sort == LibrarySort.recent,
                        () => _setSettings(sort: LibrarySort.recent),
                      ),
                      chip(
                        l.sortAlphabetical,
                        sort == LibrarySort.alpha,
                        () => _setSettings(sort: LibrarySort.alpha),
                      ),
                      chip(
                        l.sortAddedRecently,
                        sort == LibrarySort.added,
                        () => _setSettings(sort: LibrarySort.added),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: settings.libraryGrid ? l.viewAsList : l.viewAsGrid,
                  icon: Icon(
                    settings.libraryGrid
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                  ),
                  onPressed: () => _setSettings(grid: !settings.libraryGrid),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Pinned {
  const _Pinned({
    this.favorites = false,
    this.icon = Icons.music_note_rounded,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  /// The heart cover of the favourites; otherwise a square with [icon].
  final bool favorites;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
}

Widget _pinnedCover(_Pinned p, double size, {double? radius}) => p.favorites
    ? PlaylistCover(
        size: size,
        favorites: true,
        radius: radius ?? CcDims.rList,
      )
    : _IconCover(size: size, icon: p.icon);

String _subtitle(BuildContext context, LibraryEntry e) {
  final l = context.l10n;
  return switch (e.kind) {
    LibraryKind.playlist when e.smart != null => l.smartPlaylistLabel,
    LibraryKind.playlist => l.playlistCountLabel(e.count),
    LibraryKind.album =>
      '${l.kindAlbum} · ${e.variousArtists ? l.variousArtists : (e.artist ?? l.unknownArtist)}',
    LibraryKind.artist => l.kindArtist,
  };
}

String _title(BuildContext context, LibraryEntry e) =>
    e.title ??
    (e.kind == LibraryKind.artist
        ? context.l10n.unknownArtist
        : context.l10n.unknownAlbum);

Widget _cover(LibraryEntry e, double size) => switch (e.kind) {
  LibraryKind.playlist when e.smart != null => SmartCover(size: size),
  LibraryKind.artist => ArtistAvatar(
    name: e.title,
    size: size,
    coverKey: e.coverKey,
  ),
  LibraryKind.playlist => PlaylistCover(
    size: size,
    coverKeys: playlistCoverKeys(null, [e.coverKey]),
  ),
  LibraryKind.album => CoverImage(
    coverKey: e.coverKey,
    size: size,
    radius: CcDims.rList,
  ),
};

class _LibraryList extends StatelessWidget {
  const _LibraryList({
    required this.pinned,
    required this.entries,
    required this.onOpen,
  });

  final List<_Pinned> pinned;
  final List<LibraryEntry> entries;
  final void Function(LibraryEntry) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    Widget row(Widget cover, String title, String subtitle, VoidCallback tap) =>
        InkWell(
          onTap: tap,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                const SizedBox(width: CcDims.margin),
                cover,
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
                const SizedBox(width: CcDims.margin),
              ],
            ),
          ),
        );
    return ListView.builder(
      itemExtent: 64,
      itemCount: pinned.length + entries.length,
      itemBuilder: (_, i) {
        if (i < pinned.length) {
          final p = pinned[i];
          return row(
            _pinnedCover(p, 48),
            p.title,
            p.subtitle,
            p.onTap,
          );
        }
        final e = entries[i - pinned.length];
        return row(
          _cover(e, 48),
          _title(context, e),
          _subtitle(context, e),
          () => onOpen(e),
        );
      },
    );
  }
}

class _IconCover extends StatelessWidget {
  const _IconCover({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cc.surface2,
        borderRadius: BorderRadius.circular(CcDims.rList),
      ),
      child: Icon(icon, color: cc.accentSoft),
    );
  }
}

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({
    required this.pinned,
    required this.entries,
    required this.onOpen,
  });

  final List<_Pinned> pinned;
  final List<LibraryEntry> entries;
  final void Function(LibraryEntry) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    Widget tile(
      Widget Function(double) cover,
      String title,
      String subtitle,
      VoidCallback tap,
    ) {
      return InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(CcDims.rGrid),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) =>
                      Center(child: cover(c.biggest.shortestSide)),
                ),
              ),
              const SizedBox(height: 6),
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
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(CcDims.margin - 6),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.8,
      ),
      itemCount: pinned.length + entries.length,
      itemBuilder: (_, i) {
        if (i < pinned.length) {
          final p = pinned[i];
          return tile(
            (s) => _pinnedCover(p, s, radius: CcDims.rGrid),
            p.title,
            p.subtitle,
            p.onTap,
          );
        }
        final e = entries[i - pinned.length];
        return tile(
          (s) => _cover(e, s),
          _title(context, e),
          _subtitle(context, e),
          () => onOpen(e),
        );
      },
    );
  }
}
