import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/home_sections.dart';
import '../../../data/repositories/library_entries.dart';
import '../../../data/repositories/library_queries.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/activity_button.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/section_header.dart';
import '../library/album_detail_screen.dart';
import '../library/favorites_screen.dart';
import '../library/folders_sheet.dart';
import '../playlists/playlist_detail_screen.dart';
import '../settings/settings_screen.dart';

String _greeting(AppLocalizations l, int hour) =>
    switch (greetingForHour(hour)) {
      Greeting.morning => l.greetingMorning,
      Greeting.afternoon => l.greetingAfternoon,
      Greeting.evening => l.greetingEvening,
    };

/// Home: greeting, «Riprendi» tiles and horizontal shelves built from what
/// was played and added. Sections without data stay hidden.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Scaffold(body: _content(context, ref));

  Widget _content(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final albums = ref.watch(albumsProvider).value ?? const <AlbumSummary>[];
    final playlists =
        ref.watch(playlistsProvider).value ?? const <PlaylistSummary>[];
    final top = ref.watch(topTracksProvider).value ?? const <Track>[];
    final trackCount = ref.watch(
      tracksProvider(false).select((t) => t.value?.length ?? 0),
    );
    final folders = ref.watch(foldersProvider).value;
    final ctrl = ref.read(playerControllerProvider);
    final theme = Theme.of(context).textTheme;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _greeting(l, DateTime.now().hour),
              style: theme.headlineSmall,
            ),
          ),
          const ActivityButton(),
          IconButton(
            tooltip: l.navSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => ShellNav.open<void>(
              context,
              Scaffold(
                appBar: AppBar(title: Text(l.navSettings)),
                body: const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
    );

    if (trackCount == 0 && folders != null && folders.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: EmptyState(
                icon: Icons.library_music,
                message: l.addMusicFolder,
                actionLabel: l.addFolder,
                onAction: () => addFolderAndScan(ref),
                secondaryLabel: l.useDefaultFolder,
                onSecondary: () => addDefaultFolderAndScan(ref),
              ),
            ),
          ],
        ),
      );
    }

    void openAlbum(AlbumSummary a) =>
        ShellNav.open<void>(context, AlbumDetailScreen(album: a));

    // «Riprendi»: Favourites first, then what was played most recently.
    final resume = buildLibraryEntries(
      playlists: playlists,
      albums: albums,
      artists: const [],
      sort: LibrarySort.recent,
    ).where((e) => e.lastPlayedAt != null).take(5).toList();

    Widget tile(Widget cover, String title, VoidCallback onTap) => Material(
      color: cc.surface1,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            cover,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium?.copyWith(
                  color: cc.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );

    final tiles = <Widget>[
      tile(
        const PlaylistCover(size: 56, favorites: true, radius: 0),
        l.navFavorites,
        () => ShellNav.open<void>(context, const FavoritesScreen()),
      ),
      for (final e in resume)
        tile(
          e.kind == LibraryKind.playlist
              ? PlaylistCover(
                  size: 56,
                  radius: 0,
                  coverKeys: playlistCoverKeys(null, [e.coverKey]),
                )
              : CoverImage(coverKey: e.coverKey, size: 56, radius: 0),
          e.title ?? l.unknownAlbum,
          () => e.kind == LibraryKind.playlist
              ? ShellNav.open<void>(
                  context,
                  PlaylistDetailScreen(playlist: e.playlist!.playlist),
                )
              : openAlbum(e.album!),
        ),
    ];

    Widget shelf(String title, List<Widget> cards) => cards.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title),
              SizedBox(
                height: 168 + 44 * MediaQuery.textScalerOf(context).scale(1),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CcDims.margin - 6,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (_, i) => cards[i],
                ),
              ),
            ],
          );

    Widget card(
      Widget cover,
      String title,
      String subtitle,
      VoidCallback tap,
    ) => InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(CcDims.rGrid),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              const SizedBox(height: 8),
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
      ),
    );

    List<Widget> albumCards(List<AlbumSummary> list) => [
      for (final a in list)
        card(
          CoverImage(coverKey: a.coverKey, size: 140, radius: CcDims.rGrid),
          a.title ?? l.unknownAlbum,
          a.variousArtists ? l.variousArtists : (a.artist ?? l.unknownArtist),
          () => openAlbum(a),
        ),
    ];

    final topCards = [
      for (var i = 0; i < top.length; i++)
        card(
          CoverImage(
            coverKey: top[i].coverKey,
            size: 140,
            radius: CcDims.rGrid,
          ),
          top[i].title,
          top[i].artist ?? l.unknownArtist,
          () => ctrl.playFromList(
            top,
            i,
            context: const PlayContext(PlayContextKind.library),
          ),
        ),
    ];

    return SafeArea(
      child: ListView(
        children: [
          header,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
            child: LayoutBuilder(
              builder: (_, c) {
                final colW = (c.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in tiles)
                      SizedBox(width: colW, height: 56, child: t),
                  ],
                );
              },
            ),
          ),
          shelf(l.homeRecentlyPlayed, albumCards(recentlyPlayedAlbums(albums))),
          shelf(l.homeRecentlyAdded, albumCards(recentlyAddedAlbums(albums))),
          shelf(l.homeTopTracks, topCards),
          shelf(
            l.homeRediscover,
            albumCards(rediscoverAlbums(albums, DateTime.now())),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
