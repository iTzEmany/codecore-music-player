import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/activity_providers.dart';
import '../../../providers/import_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/share_hub.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/share/offers.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/yt_dlp_outdated_banner.dart';

/// Everything that runs in the background, with Cancel where it exists.
class ActivitySheet extends ConsumerWidget {
  const ActivitySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => const ActivitySheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final state = ref.watch(activityProvider);

    String title(ActivityItem a) => switch (a.kind) {
      ActivityKind.scan =>
        a.total > 0 ? l.activityScan(a.done, a.total) : l.activityScanIdle,
      ActivityKind.enrich => l.activityEnrich(a.done, a.total),
      ActivityKind.download => a.retryDelaySec == null
          ? l.activityDownload(a.name ?? '')
          : l.activityDownloadRetry(
              a.name ?? '', a.retryDelaySec!, a.done, a.total),
      ActivityKind.transfer => l.activityTransfer(a.name ?? '', a.total),
      ActivityKind.import =>
        a.paused
            ? l.activityImportPaused(a.name ?? '', a.done, a.total)
            : l.activityImport(a.name ?? '', a.done, a.total) +
                  (a.eta == null ? '' : ' · ${etaLabel(l, a.eta!)}'),
    };

    Future<void> cancelImport(ActivityItem a) async {
      final ok = await showConfirm(
        context,
        title: l.csvImportCancelTitle,
        body: l.csvImportCancelBody,
        confirmLabel: l.csvImportCancelGo,
        destructive: true,
      );
      if (ok) await ref.read(playlistImportServiceProvider).cancel(a.ref! as int);
    }

    void cancel(ActivityItem a) {
      switch (a.kind) {
        case ActivityKind.enrich:
          ref.read(enrichJobProvider.notifier).cancel();
        case ActivityKind.download:
          ref.read(downloadsProvider.notifier).cancel(a.ref! as int);
        case ActivityKind.transfer:
          final o = a.ref! as OutgoingOffer;
          final hub = ref.read(shareHubProvider);
          ref
              .read(shareHubProvider.notifier)
              .cancelOutgoing(
                o,
                hub.peers.where((p) => p.id == o.toId).firstOrNull,
              );
        case ActivityKind.import:
          cancelImport(a);
        case ActivityKind.scan:
          break;
      }
    }

    Widget row(ActivityItem a) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CcDims.margin,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title(a),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyLarge,
                ),
                if (a.running) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: a.progress),
                ] else
                  Text(
                    a.failed ? l.offerFailed : l.offerDone,
                    style: theme.bodyMedium?.copyWith(
                      color: a.failed ? cc.error : cc.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (a.kind == ActivityKind.import && a.running)
            IconButton(
              tooltip: a.paused ? l.csvImportResume : l.csvImportPause,
              icon: Icon(
                a.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              ),
              onPressed: () {
                final svc = ref.read(playlistImportServiceProvider);
                final id = a.ref! as int;
                a.paused ? svc.resume(id) : svc.pause(id);
              },
            ),
          if (a.cancellable)
            IconButton(
              tooltip: l.cancel,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => cancel(a),
            ),
        ],
      ),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CcDims.margin,
                0,
                CcDims.margin,
                8,
              ),
              child: Text(l.activityTitle, style: theme.titleMedium),
            ),
            const YtDlpOutdatedBanner(),
            if (state.isEmpty)
              Padding(
                padding: const EdgeInsets.all(CcDims.margin),
                child: Text(
                  l.activityNone,
                  style: theme.bodyMedium?.copyWith(color: cc.textMuted),
                ),
              ),
            for (final a in state.running) row(a),
            if (state.completed.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(CcDims.margin, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.activityCompleted,
                        style: theme.labelLarge?.copyWith(color: cc.textMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(downloadsProvider.notifier).clearFinished();
                        ref.read(dismissedActivityProvider.notifier).dismiss([
                          for (final c in state.completed) c.key,
                        ]);
                      },
                      child: Text(l.activityClear),
                    ),
                  ],
                ),
              ),
              for (final a in state.completed) row(a),
            ],
          ],
        ),
      ),
    );
  }
}
