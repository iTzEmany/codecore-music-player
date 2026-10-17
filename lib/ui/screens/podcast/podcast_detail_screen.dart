import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/podcast_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/podcast_providers.dart';
import '../../../services/podcast/podcast_models.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/speed_button.dart';
import 'podcast_texts.dart';

/// One podcast: its header, and its episodes (newest first) with what each one
/// is doing. Opening it refreshes the feed only if it is older than 6 hours.
class PodcastDetailScreen extends ConsumerStatefulWidget {
  const PodcastDetailScreen({super.key, required this.podcastId});

  final int podcastId;

  @override
  ConsumerState<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends ConsumerState<PodcastDetailScreen> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refresh(onlyIfStale: true));
  }

  Future<void> _refresh({bool onlyIfStale = false}) async {
    if (_refreshing) return;
    final svc = ref.read(podcastServiceProvider);
    setState(() => _refreshing = true);
    try {
      final added = onlyIfStale
          ? await svc.refreshIfStale(widget.podcastId)
          : await svc.refresh(widget.podcastId);
      if (added != null && mounted && !onlyIfStale) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(context.l10n.podcastRefreshed(added))));
      }
    } on PodcastException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(podcastErrorText(context.l10n, e.kind))));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// The downloaded episodes oldest first, so listening goes forward in time,
  /// starting at the one tapped.
  Future<void> _play(List<EpisodeRow> rows, EpisodeRow tapped, String podcastTitle) async {
    final downloaded = [
      for (final r in rows)
        if (r.downloaded) r,
    ]..sort((a, b) => (a.episode.publishedAt ?? 0).compareTo(b.episode.publishedAt ?? 0));
    final index = downloaded.indexWhere((r) => r.episode.id == tapped.episode.id);
    if (index < 0) return;
    await ref.read(playerControllerProvider).playFromList(
          [for (final r in downloaded) r.track!],
          index,
          context: PlayContext(PlayContextKind.podcast, podcastTitle),
        );
  }

  Future<void> _unsubscribe(Podcast p, int downloadedCount) async {
    final l = context.l10n;
    final ok = await showConfirm(
      context,
      title: l.podcastUnsubscribeTitle,
      body: l.podcastUnsubscribeBody(downloadedCount),
      confirmLabel: l.podcastUnsubscribe,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(podcastServiceProvider).unsubscribe(p.id);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final podcast = ref.watch(podcastProvider(widget.podcastId)).value;
    final rows = ref.watch(podcastEpisodesProvider(widget.podcastId)).value ?? const <EpisodeRow>[];
    final running = {for (final d in ref.watch(podcastDownloadsProvider)) d.episodeId: d};
    if (podcast == null) return const Scaffold();
    final downloadedCount = rows.where((r) => r.downloaded).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(podcast.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              key: const ValueKey('refresh'),
              tooltip: l.podcastRefresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
          PopupMenuButton<String>(
            key: const ValueKey('podcast-menu'),
            tooltip: l.moreActions,
            onSelected: (v) {
              if (v == 'unsubscribe') _unsubscribe(podcast, downloadedCount);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'unsubscribe',
                child: Text(l.podcastUnsubscribe, key: const ValueKey('unsubscribe')),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _Header(podcast: podcast),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(icon: Icons.podcasts_rounded, message: l.podcastNoEpisodes)
                : ListView.builder(
                    itemExtent: 84,
                    itemCount: rows.length,
                    itemBuilder: (_, i) => _EpisodeTile(
                      row: rows[i],
                      download: running[rows[i].episode.id],
                      onPlay: () => _play(rows, rows[i], podcast.title),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.podcast});

  final Podcast podcast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final checked = podcast.lastCheckedAt;
    final when = checked == null
        ? l.podcastNeverChecked
        : l.podcastLastChecked(
            DateFormat.yMMMd(locale).add_Hm().format(DateTime.fromMillisecondsSinceEpoch(checked)),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 8, CcDims.margin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CoverImage(coverKey: podcast.coverKey, size: 72, radius: CcDims.rGrid),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (podcast.author != null)
                      Text(podcast.author!, style: theme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(when, style: theme.bodySmall?.copyWith(color: cc.textMuted)),
                    const SizedBox(height: 6),
                    const Align(alignment: Alignment.centerLeft, child: SpeedButton()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(l.podcastAutoDelete, style: theme.bodyMedium)),
              DropdownButton<int?>(
                key: const ValueKey('auto-delete'),
                value: const [null, 1, 7, 30].contains(podcast.autoDeleteDays) ? podcast.autoDeleteDays : null,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.podcastAutoDeleteNever)),
                  for (final d in const [1, 7, 30])
                    DropdownMenuItem(value: d, child: Text(l.podcastAutoDeleteAfter(d))),
                ],
                onChanged: (d) => ref.read(podcastRepositoryProvider).setAutoDeleteDays(podcast.id, d),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({required this.row, required this.download, required this.onPlay});

  final EpisodeRow row;
  final EpisodeDownload? download;
  final VoidCallback onPlay;

  String _status(AppLocalizations l) {
    final d = download;
    if (d != null && d.active) {
      return l.podcastStateDownloading(((d.progress ?? 0) * 100).round());
    }
    if (d != null && d.status == EpisodeDownloadStatus.failed && d.error != null) {
      return podcastErrorText(l, d.error!);
    }
    if (row.episode.played) return l.podcastStateHeard;
    final t = row.track;
    final resume = t?.resumePositionMs;
    if (t != null && resume != null && t.durationMs > resume) {
      return l.podcastStateRemaining(etaLabel(l, Duration(milliseconds: t.durationMs - resume)));
    }
    return row.downloaded ? l.podcastStateDownloaded : '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final e = row.episode;
    final locale = Localizations.localeOf(context).toString();
    final date = e.publishedAt == null
        ? null
        : DateFormat.yMMMd(locale).format(DateTime.fromMillisecondsSinceEpoch(e.publishedAt!));
    final status = _status(l);
    final repo = ref.read(podcastRepositoryProvider);
    final busy = download?.active ?? false;
    final Widget action;
    if (busy) {
      action = IconButton(
        key: ValueKey('cancel-${e.id}'),
        tooltip: l.cancel,
        icon: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, value: download?.progress),
        ),
        onPressed: () => ref.read(podcastDownloadsProvider.notifier).cancel(e.id),
      );
    } else if (row.downloaded) {
      action = IconButton(
        key: ValueKey('play-${e.id}'),
        tooltip: l.play,
        icon: const Icon(Icons.play_circle_rounded),
        onPressed: onPlay,
      );
    } else {
      action = IconButton(
        key: ValueKey('download-${e.id}'),
        tooltip: l.ytDownload,
        icon: const Icon(Icons.download_rounded),
        onPressed: () => ref.read(podcastDownloadsProvider.notifier).add(e.id, e.title),
      );
    }
    return InkWell(
      onTap: row.downloaded && !busy ? onPlay : null,
      child: Padding(
        padding: const EdgeInsets.only(left: CcDims.margin, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge?.copyWith(color: e.played ? cc.textMuted : null),
                  ),
                  Text(
                    [
                      ?date,
                      if (e.durationMs != null) formatDuration(e.durationMs!),
                      if (status.isNotEmpty) status,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall?.copyWith(color: cc.textMuted),
                  ),
                ],
              ),
            ),
            action,
            PopupMenuButton<String>(
              key: ValueKey('menu-${e.id}'),
              tooltip: l.moreActions,
              onSelected: (v) async {
                final now = DateTime.now().millisecondsSinceEpoch;
                switch (v) {
                  case 'heard':
                    await repo.markPlayed(e.id, !e.played, now: now);
                  case 'delete':
                    final d = await ref.read(episodeDownloaderProvider.future);
                    await d.deleteFile(e.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'heard',
                  child: Text(e.played ? l.podcastMarkNotHeard : l.podcastMarkHeard),
                ),
                if (row.downloaded)
                  PopupMenuItem(value: 'delete', child: Text(l.podcastDeleteFile)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
