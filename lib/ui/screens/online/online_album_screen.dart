import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
import '../../../providers/library_overlap_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../providers/ytm_catalog_providers.dart';
import '../../../services/import/import_options.dart';
import '../../../services/import/playlist_import_service.dart' show ytmAlbumSourceKind;
import '../../../services/online/album_download_plan.dart';
import '../../../services/online/ytm_artist.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/net_thumbnail.dart';
import '../import/import_detail_screen.dart';
import 'artist_page_screen.dart';
import 'artist_page_sections.dart';
import 'catalog_error_view.dart';
import 'online_page_frame.dart';
import 'online_song_row.dart';

/// An album, single or EP of YouTube Music: cover, numbered songs with
/// «Ascolta» and «Scarica», and «Scarica album». [release] is what the page
/// was opened from (title and cover are shown while it loads).
class OnlineAlbumScreen extends ConsumerWidget {
  const OnlineAlbumScreen({super.key, required this.browseId, this.release});

  final String browseId;
  final YtmRelease? release;

  String get _listKey => 'ytm-album:$browseId';

  Future<void> _downloadAlbum(BuildContext context, WidgetRef ref, YtmAlbum album) async {
    final l = context.l10n;
    final index = ref.read(downloadIndexProvider).value;
    // What the import links instead of downloading: the songs it already has.
    final plan = albumDownloadPlan(
        album, (r) => index?.contains(r.id, source: r.source) ?? false);
    if (plan.tracks.isEmpty) return;
    final body = [
      l.ytmAlbumConfirmBody(plan.tracks.length, l.durationMinutes(plan.duration.inMinutes),
          formatBytes(plan.estimatedBytes)),
      if (plan.owned > 0) l.ytmAlbumConfirmOwned(plan.owned),
    ].join('\n');
    final ok = await showConfirm(
      context,
      title: l.ytmDownloadAlbumTitle(album.title),
      body: body,
      confirmLabel: l.ytDownload,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final id = await ref.read(playlistImportServiceProvider).startFromResults(
            plan.importName,
            plan.tracks,
            options: ImportOptions(folderPath: plan.folder, fetchCovers: true),
            sourceKind: ytmAlbumSourceKind,
          );
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(l.ytmAlbumStarted(plan.importName)),
          action: SnackBarAction(
            label: l.ytmShowImport,
            onPressed: () => nav.push(MaterialPageRoute<void>(
                builder: (_) => ImportDetailScreen(importId: id))),
          ),
        ));
    } on Object catch (e, st) {
      AppLog.e('album download: could not start the import', e, st);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.loadFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(onlineAlbumProvider(browseId));
    final data = page.value;
    final album = data?.value;
    final overlap = ref.watch(localOverlapProvider(album?.artist?.name ?? ''));
    final songs = [for (final t in album?.tracks ?? const <YtmAlbumTrack>[]) t.result];
    return OnlinePageFrame(
      title: album?.title ?? release?.title ?? '',
      selectionKey: _listKey,
      pickable: songs,
      onRefresh: () async {
        try {
          await ref
              .read(ytmCatalogProvider)
              .album(browseId, ref.read(ytmLanguageProvider), refresh: true);
        } on Object catch (e) {
          AppLog.w('album page: refresh failed ($e)');
        }
        ref.invalidate(onlineAlbumProvider(browseId));
      },
      slivers: [
        SliverToBoxAdapter(
          child: _AlbumHeader(
            album: album,
            release: release,
            onDownload: album == null ? null : () => _downloadAlbum(context, ref, album),
          ),
        ),
        if (data != null && data.stale)
          SliverToBoxAdapter(child: OfflineNotice(fetchedAt: data.fetchedAt)),
        if (album != null)
          SliverList.builder(
            itemCount: album.tracks.length,
            itemBuilder: (_, i) => OnlineSongTile(
              result: album.tracks[i].result,
              index: i,
              number: album.tracks[i].number ?? i + 1,
              selectionKey: _listKey,
              ownedLocally: album.artist != null && overlap.owns(album.tracks[i].result),
            ),
          )
        else if (page.hasError)
          SliverToBoxAdapter(
            child: CatalogErrorView(
              error: page.error!,
              onRetry: () => ref.invalidate(onlineAlbumProvider(browseId)),
            ),
          )
        else
          const SliverToBoxAdapter(child: PageSkeleton(rows: 8)),
      ],
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.album, required this.release, required this.onDownload});

  final YtmAlbum? album;
  final YtmRelease? release;
  final VoidCallback? onDownload;

  static const _cover = 120.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final a = album;
    final title = a?.title ?? release?.title ?? '';
    final kind = a == null
        ? release?.subtitle ?? ''
        : [a.kindLabel, a.year].whereType<String>().where((s) => s.isNotEmpty).join(' • ');
    var total = Duration.zero;
    for (final t in a?.tracks ?? const <YtmAlbumTrack>[]) {
      total += t.result.duration ?? Duration.zero;
    }
    final stats = a == null || a.tracks.isEmpty
        ? ''
        : [
            l.tracksCount(a.tracks.length),
            if (total > Duration.zero) l.durationMinutes(total.inMinutes),
          ].join(' • ');
    final artist = a?.artist;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 0, CcDims.margin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetThumbnail(
                url: thumbAt(context, a?.coverUrl ?? release?.thumbnailUrl, _cover),
                width: _cover,
                height: _cover,
                radius: CcDims.rGrid,
                icon: Icons.album_rounded,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.titleLarge),
                    if (artist != null && artist.name.isNotEmpty)
                      InkWell(
                        key: const ValueKey('album-artist'),
                        onTap: artist.id.isEmpty
                            ? null
                            : () => ShellNav.open<void>(context, ArtistPageScreen(artist: artist)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(artist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyLarge?.copyWith(
                                  color: artist.id.isEmpty ? null : cc.accentSoft)),
                        ),
                      ),
                    if (kind.isNotEmpty)
                      Text(kind, style: theme.bodyMedium?.copyWith(color: cc.textMuted)),
                    if (stats.isNotEmpty)
                      Text(stats, style: theme.bodyMedium?.copyWith(color: cc.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('download-album'),
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded),
            label: Text(l.ytmDownloadAlbum),
          ),
        ],
      ),
    );
  }
}
