import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/podcast_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/podcast_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/empty_state.dart';
import 'podcast_detail_screen.dart';
import 'podcast_subscribe_sheet.dart';
import 'podcast_texts.dart';
import '../../widgets/show_msg.dart';
import '../../widgets/cc_app_bar.dart';

/// Library → Podcast: the shows the user subscribed to. Opening it tidies up
/// (interrupted downloads, heard episodes past their limit) but never goes to
/// the network: that only happens on «Aggiorna».
class PodcastsScreen extends ConsumerStatefulWidget {
  const PodcastsScreen({super.key});

  @override
  ConsumerState<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends ConsumerState<PodcastsScreen> {
  bool _refreshing = false;

  Future<void> _refreshAll() async {
    final l = context.l10n;
    setState(() => _refreshing = true);
    final report = await ref.read(podcastServiceProvider).refreshAll();
    if (!mounted) return;
    setState(() => _refreshing = false);
    final text = report.failed.isEmpty
        ? l.podcastRefreshed(report.totalAdded)
        : '${l.podcastRefreshed(report.totalAdded)}, '
              '${l.podcastRefreshFailed(report.failed.length)}: '
              '${podcastErrorText(l, report.failed.values.first.kind)}';
    showMsg(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    // Watching keeps the maintenance alive while the page is open.
    ref.watch(podcastMaintenanceProvider);
    final podcasts = ref.watch(podcastsProvider).value ?? const [];
    return Scaffold(
      appBar: CcAppBar(
        title: l.podcastsTitle,
        actions: [
          if (podcasts.isNotEmpty)
            _refreshing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('refresh-all'),
                    tooltip: l.podcastRefreshAll,
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _refreshAll,
                  ),
          IconButton(
            key: const ValueKey('add-podcast'),
            tooltip: l.podcastAdd,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => PodcastSubscribeSheet.show(context),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: podcasts.isEmpty
              ? EmptyState(
                  icon: Icons.podcasts_rounded,
                  message: l.podcastsEmpty,
                  help: l.podcastsNotice,
                  actionLabel: l.podcastAdd,
                  onAction: () => PodcastSubscribeSheet.show(context),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CcDims.margin,
                        CcDims.gap8,
                        CcDims.margin,
                        CcDims.gap4,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.podcastsNotice,
                          style: theme.bodySmall?.copyWith(color: cc.textMuted),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemExtent: 72,
                        itemCount: podcasts.length,
                        itemBuilder: (_, i) => _PodcastTile(podcasts[i]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PodcastTile extends StatelessWidget {
  const _PodcastTile(this.summary);

  final PodcastSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = summary.podcast;
    final line = [
      l.podcastEpisodesCount(summary.episodeCount),
      if (summary.toListen > 0) l.podcastToListen(summary.toListen),
    ].join(', ');
    return ListTile(
      key: ValueKey('podcast-${p.id}'),
      leading: CoverImage(coverKey: p.coverKey, size: 56, radius: CcDims.rGrid),
      title: Text(
        p.title,
        style: Theme.of(context).textTheme.titleSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [if (p.author != null) p.author!, line].join(', '),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.cc.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () =>
          ShellNav.open<void>(context, PodcastDetailScreen(podcastId: p.id)),
    );
  }
}
