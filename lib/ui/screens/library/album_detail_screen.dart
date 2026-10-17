import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/library_queries.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/collection_header.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/error_state.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import '../devices/devices_sheet.dart';
import '../cleanup/album_merge_dialog.dart';
import '../playlists/playlist_dialogs.dart';
import 'artist_screen.dart';

/// «12 brani, 48 min».
String tracksAndMinutes(BuildContext context, int tracks, int durationMs) {
  final l = context.l10n;
  final minutes = durationMs <= 0
      ? 0
      : (durationMs / 60000).round().clamp(1, 99999);
  return l.tracksAndDuration(l.tracksCount(tracks), l.durationMinutes(minutes));
}

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tracks = ref.watch(albumTracksProvider(album.albumKey));
    final compact = ref.watch(settingsProvider).compactMode;
    final cc = context.cc;
    final name = album.title ?? l.unknownAlbum;
    final playCtx = PlayContext(PlayContextKind.album, name);
    final artistName = album.variousArtists
        ? l.variousArtists
        : (album.artist ?? l.unknownArtist);
    final list = tracks.value ?? const <Track>[];
    final ctrl = ref.read(playerControllerProvider);

    void snack(String text) => ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));

    final meta = [
      if (album.year != null) '${album.year}',
      tracksAndMinutes(context, album.trackCount, album.durationMs),
    ].join(' · ');

    final discs = {for (final t in list) t.discNumber ?? 1};
    final multiDisc = discs.length > 1;
    // Flat list of rows and disc headers, in disc order.
    final items = <Object>[];
    int? lastDisc;
    for (final t in list) {
      final d = t.discNumber ?? 1;
      if (multiDisc && d != lastDisc) items.add(d);
      lastDisc = d;
      items.add(t);
    }
    final position = {for (var i = 0; i < list.length; i++) list[i].id: i};
    final extent = trackRowExtentOf(context, compact);
    final key = 'album:${album.albumKey}';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in list) t.id],
    );

    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: CollectionScaffold(
        selectionBar: SelectionBarSlot(listKey: key, tracks: list),
        title: name,
        name: name,
        coverKey: album.coverKey,
        cover: (s) =>
            CoverImage(coverKey: album.coverKey, size: s, radius: CcDims.rGrid),
        subtitle: album.variousArtists || album.artist == null
            ? Text(artistName, style: Theme.of(context).textTheme.bodyLarge)
            : InkWell(
                onTap: () => ShellNav.open<void>(
                  context,
                  ArtistDetailScreen(
                    artist: ArtistSummary(
                      key: album.artist!.trim().toLowerCase(),
                      name: album.artist,
                      trackCount: 0,
                      albumCount: 0,
                    ),
                  ),
                ),
                child: Text(
                  artistName,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700, color: cc.text),
                ),
              ),
        meta: '${l.kindAlbum} · $meta',
        onPlay: list.isEmpty
            ? null
            : () => ctrl.playFromList(list, 0, context: playCtx),
        onShuffle: list.isEmpty
            ? null
            : () async {
                await ctrl.setShuffle(true);
                await ctrl.playFromList(list, 0, context: playCtx);
              },
        menu: PopupMenuButton<String>(
          tooltip: l.moreActions,
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) {
            switch (v) {
              case 'queue':
                for (final t in list) {
                  ctrl.addToQueue(t.id);
                }
                snack(l.addedToQueue);
              case 'playlist':
                showAddToPlaylistSheet(context, ref, list);
              case 'share':
                DevicesSheet.show(
                  context,
                  trackIds: [for (final t in list) t.id],
                );
              case 'enrich':
                final ok = ref.read(enrichJobProvider.notifier).start([
                  for (final t in list) t.id,
                ]);
                if (!ok) snack(l.enrichBusy);
              case 'merge':
                // The album this page shows is gone once merged: leave it.
                showAlbumMergeDialog(context, ref, album).then((merged) {
                  if (merged && context.mounted) Navigator.of(context).maybePop();
                });
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'queue', child: Text(l.addToQueue)),
            PopupMenuItem(value: 'playlist', child: Text(l.addToPlaylist)),
            PopupMenuItem(value: 'share', child: Text(l.shareMenu)),
            PopupMenuItem(value: 'enrich', child: Text(l.enrichAlbum)),
            PopupMenuItem(value: 'merge', child: Text(l.albumMergeWith)),
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
                  onRetry: () =>
                      ref.invalidate(albumTracksProvider(album.albumKey)),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                if (it is int) return DiscHeader(it);
                final t = it as Track;
                final at = position[t.id] ?? 0;
                return SizedBox(
                  height: extent,
                  child: LiveTrackRow(
                    track: t,
                    compact: compact,
                    variant: TrackRowVariant.album,
                    albumArtist: album.artist,
                    index: at + 1,
                    selection: selection,
                    onTap: () => ctrl.playFromList(list, at, context: playCtx),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
