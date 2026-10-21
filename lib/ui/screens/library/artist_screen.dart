import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/library_queries.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../core/constants.dart';
import '../../shell/shell_nav.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/album_grid.dart';
import '../../widgets/artist_avatar.dart';
import '../../widgets/collection_header.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import '../online/artist_picker_sheet.dart';
import 'album_detail_screen.dart';

/// An artist: Play / Shuffle over all their tracks, the five most played and
/// the albums in a grid.
class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistSummary artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final albums = ref.watch(artistAlbumsProvider(artist.key));
    final tracks = ref.watch(artistTracksProvider(artist.key));
    final compact = ref.watch(settingsProvider).compactMode;
    final ctrl = ref.read(playerControllerProvider);
    final name = artist.name ?? l.unknownArtist;
    final playCtx = PlayContext(PlayContextKind.artist, name);
    final list = tracks.value ?? const <Track>[];
    final albumList = albums.value ?? const <AlbumSummary>[];
    // Most present cover among the albums, for the avatar and the backdrop.
    final coverKey =
        artist.coverKey ??
        albumList.map((a) => a.coverKey).whereType<String>().firstOrNull;
    final top = ([
      ...list.where((t) => t.playCount > 0),
    ]..sort((a, b) => b.playCount.compareTo(a.playCount))).take(5).toList();
    final extent = trackRowExtentOf(context, compact);
    final meta = l.artistMeta(
      l.albumsCount(albumList.length),
      l.tracksCount(list.length),
    );
    // The rows shown here are the most played ones.
    final key = 'artist:${artist.key}';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in top) t.id],
    );
    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: CollectionScaffold(
        selectionBar: SelectionBarSlot(listKey: key, tracks: top),
        title: name,
        name: name,
        coverKey: coverKey,
        cover: (s) => ArtistAvatar(
          name: artist.name,
          size: s.clamp(0.0, 160.0),
          coverKey: coverKey,
        ),
        meta: meta,
        menu: kEnableYoutube && artist.name != null
            ? IconButton(
                key: const ValueKey('artist-on-ytm'),
                tooltip: l.ytmOnYoutubeMusic,
                onPressed: () => openYtmArtist(context, ref, artist.name!,
                    open: (page) => ShellNav.open<void>(context, page)),
                icon: const Icon(Icons.smart_display_rounded),
              )
            : null,
        onPlay: list.isEmpty
            ? null
            : () => ctrl.playFromList(list, 0, context: playCtx),
        onShuffle: list.isEmpty
            ? null
            : () async {
                await ctrl.setShuffle(true);
                await ctrl.playFromList(list, 0, context: playCtx);
              },
        slivers: [
          if (tracks.hasError || albums.hasError)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: loadErrorState(
                  context,
                  tracks.error ?? albums.error!,
                  StackTrace.current,
                  onRetry: () {
                    ref.invalidate(artistTracksProvider(artist.key));
                    ref.invalidate(artistAlbumsProvider(artist.key));
                  },
                ),
              ),
            ),
          if (top.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeader(l.mostPlayed)),
            SliverList.builder(
              itemCount: top.length,
              itemBuilder: (_, i) => SizedBox(
                height: extent,
                child: LiveTrackRow(
                  track: top[i],
                  compact: compact,
                  selection: selection,
                  onTap: () => ctrl.playFromList(top, i, context: playCtx),
                ),
              ),
            ),
          ],
          if (albumList.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeader(l.albumsSection)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: CcDims.margin - 8,
              ),
              sliver: SliverToBoxAdapter(
                child: AlbumGrid(
                  albums: albumList,
                  shrinkWrap: true,
                  onOpen: (a) =>
                      ShellNav.open<void>(context, AlbumDetailScreen(album: a)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
