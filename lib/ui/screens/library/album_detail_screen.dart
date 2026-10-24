import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/library_queries.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../services/online/enrichment_service.dart' show needsEnrichment;
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
import '../../widgets/motion.dart';
import '../../widgets/show_msg.dart';

/// «1 ora e 52 minuti»; never «0 minuti» (under a minute rounds up).
String durationWords(AppLocalizations l, int ms) {
  final minutes = ms > 0 ? (ms / 60000).ceil() : 0;
  if (minutes < 60) return l.minutesWords(minutes);
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0
      ? l.hoursWords(h)
      : l.hoursAndMinutes(l.hoursWords(h), l.minutesWords(m));
}

/// «2004, 12 brani, 48 minuti».
String collectionMeta(
  AppLocalizations l, {
  int? year,
  required int tracks,
  required int durationMs,
  int? albums,
}) => tracks == 0
    ? l.collectionNoTracks
    : [
        if (albums != null) l.albumsCount(albums),
        if (year != null) '$year',
        l.tracksCount(tracks),
        durationWords(l, durationMs),
      ].join(', ');

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tracks = ref.watch(albumTracksProvider(album.albumKey));
    final compact = ref.watch(settingsProvider).compactMode;
    final name = album.title ?? l.unknownAlbum;
    final playCtx = PlayContext(PlayContextKind.album, name);
    final list = tracks.value ?? const <Track>[];
    final ctrl = ref.read(playerControllerProvider);

    // Follow the rows once loaded: the summary is a snapshot (a track moved
    // away or edited changes the album under this page).
    final meta = collectionMeta(
      l,
      year: album.year,
      tracks: tracks.hasValue ? list.length : album.trackCount,
      durationMs: tracks.hasValue
          ? list.fold<int>(0, (sum, t) => sum + t.durationMs)
          : album.durationMs,
    );

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
        subtitle: _AlbumSubtitle(album: album),
        meta: meta,
        onPlay: list.isEmpty
            ? null
            : () => ctrl.playAll(list, context: playCtx),
        onShuffle: list.isEmpty
            ? null
            : ctrl.toggleShuffle,
        menu: _AlbumMenu(album: album, tracks: list),
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
            EntranceScope(
              child: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                if (it is int) return DiscHeader(it);
                final t = it as Track;
                final at = position[t.id] ?? 0;
                return SizedBox(
                  height: extent,
                  child: EnterOnce(
                    index: i,
                    child: LiveTrackRow(
                      track: t,
                      compact: compact,
                      variant: TrackRowVariant.album,
                      albumArtist: album.artist,
                      index: at + 1,
                      selection: selection,
                      onTap: () => ctrl.playFromList(list, at, context: playCtx),
                    ),
                  ),
                );
              },
            ),
            ),
        ],
      ),
    );
  }
}

class _AlbumSubtitle extends StatelessWidget {
  const _AlbumSubtitle({required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final artistName = album.variousArtists
        ? l.variousArtists
        : (album.artist ?? l.unknownArtist);
    return album.variousArtists || album.artist == null
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
              );
  }
}

class _AlbumMenu extends ConsumerWidget {
  const _AlbumMenu({required this.album, required this.tracks});

  final AlbumSummary album;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = tracks;
    final ctrl = ref.read(playerControllerProvider);
    return PopupMenuButton<_AlbumAction>(
          tooltip: l.moreActions,
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) {
            switch (v) {
              case _AlbumAction.queue:
                for (final t in list) {
                  ctrl.addToQueue(t.id);
                }
                showMsg(context, l.addedToQueue);
              case _AlbumAction.playlist:
                showAddToPlaylistSheet(context, ref, list);
              case _AlbumAction.share:
                DevicesSheet.show(
                  context,
                  trackIds: [for (final t in list) t.id],
                );
              case _AlbumAction.enrich:
                final todo = [
                  for (final t in list)
                    if (needsEnrichment(t)) t.id,
                ];
                if (todo.isEmpty) {
                  showMsg(context, l.enrichNothingToDo);
                } else if (!ref.read(enrichJobProvider.notifier).start(todo)) {
                  showMsg(context, l.enrichBusy);
                }
              case _AlbumAction.merge:
                // The album this page shows is gone once merged: leave it.
                showAlbumMergeDialog(context, ref, album).then((merged) {
                  if (merged && context.mounted) Navigator.of(context).maybePop();
                });
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: _AlbumAction.queue, child: Text(l.addToQueue)),
            PopupMenuItem(value: _AlbumAction.playlist, child: Text(l.addToPlaylist)),
            PopupMenuItem(value: _AlbumAction.share, child: Text(l.shareMenu)),
            PopupMenuItem(value: _AlbumAction.enrich, child: Text(l.enrichAlbum)),
            PopupMenuItem(value: _AlbumAction.merge, child: Text(l.albumMergeWith)),
          ],
        );
  }
}

enum _AlbumAction { queue, playlist, share, enrich, merge }
