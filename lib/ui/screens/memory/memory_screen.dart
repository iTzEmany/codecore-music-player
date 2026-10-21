import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/memory_queries.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/memory_providers.dart';
import '../../../providers/nav_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/error_state.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_actions.dart';
import '../cleanup/duplicates_screen.dart';
import '../library/album_detail_screen.dart';
import '../library/favorites_screen.dart';
import '../playlists/playlist_detail_screen.dart';
import '../settings/missing_tracks_screen.dart';
import '../stats/stats_screen.dart' show formatListened;
import 'memory_app_data.dart';
import 'memory_widgets.dart';
import 'never_played_screen.dart';

/// Fourth tab: how much space the library takes, split by playlist, format,
/// folder and track, what was never played, and what the app itself keeps.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  /// Nothing is measured until the tab is first shown (the tabs share an
  /// `IndexedStack`, which builds them all at start-up).
  bool _opened = false;

  void _refresh() {
    ref
      ..invalidate(memoryBreakdownProvider)
      ..invalidate(appDataUsageProvider)
      ..invalidate(musicDiskSpaceProvider);
  }

  Future<void> _pullToRefresh() async {
    _refresh();
    await ref.read(memoryBreakdownProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final selected = ref.watch(navIndexProvider) == NavTab.memory.index;
    ref.listen(navIndexProvider, (prev, next) {
      if (next == NavTab.memory.index && prev != next && _opened) _refresh();
    });
    if (selected) _opened = true;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 12, CcDims.margin, 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          l.navMemory,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          header,
          Expanded(
            child: _opened
                ? RefreshIndicator(
                    onRefresh: _pullToRefresh,
                    child: _MemoryList(onRetry: _refresh),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MemoryList extends ConsumerWidget {
  const _MemoryList({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(memoryTotalsProvider);
    final breakdown = ref.watch(memoryBreakdownProvider);
    final error = totals.error ?? breakdown.error;
    if (error != null) {
      return loadErrorState(
        context,
        error,
        totals.stackTrace ?? breakdown.stackTrace ?? StackTrace.current,
        onRetry: onRetry,
      );
    }
    final t = totals.value, b = breakdown.value;
    if (t == null || b == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _SummaryCard(totals: t),
        ..._playlists(context, b),
        ..._weights(
          context,
          context.l10n.memoryByFormat,
          b.formats,
          name: (g) => g.name.toUpperCase(),
          subtitle: (g) => context.l10n.tracksCount(g.totals.trackCount),
        ),
        ..._weights(
          context,
          context.l10n.memoryByFolder,
          b.folders,
          name: (g) => g.path == null ? context.l10n.memoryNoFolder : g.name,
          subtitle: (g) {
            final n = context.l10n.tracksCount(g.totals.trackCount);
            return g.path == null ? n : '$n · ${g.path}';
          },
        ),
        ..._heaviest(context, b),
        ..._neverPlayed(context, b, t),
        const MemoryAppDataSection(),
        ..._tools(context, ref),
      ],
    );
  }

  List<Widget> _weights(
    BuildContext context,
    String title,
    List<SizeGroup> groups, {
    required String Function(SizeGroup) name,
    required String Function(SizeGroup) subtitle,
  }) {
    if (groups.isEmpty) return const [];
    final max = groups.first.totals.sizeBytes;
    return [
      SectionHeader(title),
      for (final g in groups)
        WeightRow(
          title: name(g),
          subtitle: subtitle(g),
          bytes: g.totals.sizeBytes,
          fraction: shareOf(g.totals.sizeBytes, max),
        ),
    ];
  }

  List<Widget> _playlists(BuildContext context, MemoryBreakdown b) {
    final l = context.l10n;
    final theme = Theme.of(context).textTheme;
    if (b.playlists.isEmpty) return const [];
    final max = b.playlists.first.totals.sizeBytes;
    return [
      SectionHeader(l.memoryPlaylists),
      for (final g in b.playlists)
        WeightRow(
          leading: PlaylistCover(
            size: 40,
            favorites: g.isFavorites,
            coverKeys: playlistCoverKeys(g.playlist?.coverKey, const []),
          ),
          title: g.isFavorites ? l.navFavorites : g.name,
          subtitle: _countAndTime(l, g.totals),
          bytes: g.totals.sizeBytes,
          fraction: shareOf(g.totals.sizeBytes, max),
          onTap: () => ShellNav.open<void>(
            context,
            g.playlist == null
                ? const FavoritesScreen()
                : PlaylistDetailScreen(playlist: g.playlist!),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(CcDims.margin, 8, CcDims.margin, 0),
        child: Text(
          l.memoryPlaylistsNote,
          style: theme.bodySmall?.copyWith(color: context.cc.textMuted),
        ),
      ),
    ];
  }

  List<Widget> _heaviest(BuildContext context, MemoryBreakdown b) {
    final l = context.l10n;
    if (b.heaviestTracks.isEmpty) return const [];
    final theme = Theme.of(context).textTheme;
    Widget sub(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 8, CcDims.margin, 0),
      child: Text(
        text,
        style: theme.titleSmall?.copyWith(color: context.cc.textMuted),
      ),
    );
    final maxTrack = b.heaviestTracks.first.sizeBytes;
    final maxAlbum = b.heaviestAlbums.firstOrNull?.sizeBytes ?? 0;
    return [
      SectionHeader(l.memoryHeaviest),
      sub(l.memoryHeaviestTracks),
      for (final t in b.heaviestTracks)
        _TrackWeight(
          title: t.title,
          subtitle: t.artist,
          coverKey: t.coverKey,
          bytes: t.sizeBytes,
          fraction: shareOf(t.sizeBytes, maxTrack),
          track: t,
        ),
      if (b.heaviestAlbums.isNotEmpty) sub(l.memoryHeaviestAlbums),
      for (final a in b.heaviestAlbums)
        WeightRow(
          leading: CoverImage(coverKey: a.album.coverKey, size: 40),
          title: a.album.title ?? l.unknownAlbum,
          subtitle: a.album.variousArtists ? l.variousArtists : a.album.artist,
          bytes: a.sizeBytes,
          fraction: shareOf(a.sizeBytes, maxAlbum),
          onTap: () => ShellNav.open<void>(
            context,
            AlbumDetailScreen(album: a.album),
          ),
        ),
    ];
  }

  List<Widget> _neverPlayed(
    BuildContext context,
    MemoryBreakdown b,
    SizeTotals library,
  ) {
    final l = context.l10n;
    final n = b.neverPlayed;
    return [
      SectionHeader(l.memoryNeverPlayed),
      WeightRow(
        leading: Icon(
          Icons.headphones_rounded,
          size: 40,
          color: context.cc.textMuted,
        ),
        title: l.memoryNeverPlayed,
        subtitle: n.trackCount == 0
            ? l.memoryNeverPlayedNone
            : _countAndTime(l, n),
        bytes: n.sizeBytes,
        fraction: shareOf(n.sizeBytes, library.sizeBytes),
        onTap: n.trackCount == 0
            ? null
            : () => ShellNav.open<void>(context, const NeverPlayedScreen()),
      ),
    ];
  }

  List<Widget> _tools(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final missing = ref.watch(
      missingTracksProvider.select((m) => m.value?.length),
    );
    return [
      SectionHeader(l.memoryTools),
      ListTile(
        leading: const Icon(Icons.content_copy_rounded),
        title: Text(l.duplicatesTitle),
        subtitle: Text(l.duplicatesTileHint),
        onTap: () => ShellNav.open<void>(context, const DuplicatesScreen()),
      ),
      ListTile(
        leading: const Icon(Icons.link_off_rounded),
        title: Text(l.missingTracksTitle),
        subtitle: missing == null ? null : Text(l.tracksCount(missing)),
        onTap: () => ShellNav.open<void>(context, const MissingTracksScreen()),
      ),
    ];
  }
}

String _countAndTime(AppLocalizations l, SizeTotals t) => l.tracksAndDuration(
  l.tracksCount(t.trackCount),
  formatListened(l, t.durationMs),
);

class _TrackWeight extends ConsumerWidget {
  const _TrackWeight({
    required this.title,
    required this.subtitle,
    required this.coverKey,
    required this.bytes,
    required this.fraction,
    required this.track,
  });

  final String title;
  final String? subtitle, coverKey;
  final int bytes;
  final double fraction;
  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) => WeightRow(
    leading: CoverImage(coverKey: coverKey, size: 40),
    title: title,
    subtitle: subtitle,
    bytes: bytes,
    fraction: fraction,
    onTap: () => showTrackActions(context, ref, track),
  );
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.totals});

  final SizeTotals totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final disk = ref.watch(musicDiskSpaceProvider).value;
    return MemoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.memorySummary, style: theme.titleSmall),
          const SizedBox(height: 8),
          Text(formatBytes(totals.sizeBytes), style: theme.headlineMedium),
          Text(
            _countAndTime(l, totals),
            style: theme.bodyMedium?.copyWith(color: cc.textMuted),
          ),
          if (disk != null) ...[
            const SizedBox(height: 16),
            DeviceBar(
              musicBytes: totals.sizeBytes,
              otherBytes: (disk.usedBytes - totals.sizeBytes).clamp(
                0,
                disk.totalBytes,
              ),
              freeBytes: disk.freeBytes,
            ),
            const SizedBox(height: 8),
            Text(
              l.memoryDeviceLine(
                formatBytes(disk.freeBytes),
                formatBytes(disk.totalBytes),
              ),
              style: theme.bodySmall?.copyWith(color: cc.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
