import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/player_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/dismiss_background.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_row.dart';

/// The queue as a draggable modal sheet (Now Playing, desktop bar).
Future<void> showQueueSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.7,
    maxChildSize: 0.95,
    builder: (_, sc) => QueueSheet(scrollController: sc),
  ),
);

/// «Coda»: the playing track and what comes next (already played tracks are
/// hidden). Rows reorder with the handle and dismiss with a swipe + undo.
class QueueSheet extends ConsumerWidget {
  const QueueSheet({
    super.key,
    required this.scrollController,
    this.showTitle = true,
  });

  final ScrollController scrollController;

  /// The desktop side panel already has its own «Coda» title.
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final queue = ref.watch(queueProvider).value ?? const <Track>[];
    ref.watch(currentTrackProvider.select((t) => t.value?.id));
    final ctrl = ref.read(playerControllerProvider);
    if (queue.isEmpty) {
      return Center(child: Text(l.emptyQueue));
    }
    final at = ref.read(audioHandlerProvider).currentIndex;
    final current = at >= 0 && at < queue.length ? queue[at] : null;
    final first = current == null ? 0 : at + 1;
    final upcoming = queue.sublist(first);
    // Stable key per entry: the same track may sit twice in the queue.
    final seen = <int, int>{};
    final keys = [
      for (final t in upcoming)
        'q-${t.id}-${seen[t.id] = (seen[t.id] ?? -1) + 1}',
    ];

    Future<void> clearNext() async {
      final removed = [...upcoming];
      for (var i = 0; i < removed.length; i++) {
        await ctrl.removeFromQueue(first);
      }
      if (!context.mounted) return;
      showUndoSnack(context, l.queueCleared, () {
        for (final t in removed) {
          ctrl.addToQueue(t.id);
        }
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: showTitle
                    ? Text(
                        l.queue,
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    : const SizedBox.shrink(),
              ),
              if (upcoming.isNotEmpty)
                TextButton(onPressed: clearNext, child: Text(l.queueClear)),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            scrollController: scrollController,
            buildDefaultDragHandles: false,
            proxyDecorator: (child, _, anim) =>
                ccDragProxy(context, child, anim),
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (current != null) ...[
                  SectionHeader(l.queueNowPlaying),
                  SizedBox(
                    height: 64,
                    child: LiveTrackRow(
                      track: current,
                      onTap: ctrl.togglePlayPause,
                    ),
                  ),
                ],
                if (upcoming.isNotEmpty) SectionHeader(l.queueNext),
              ],
            ),
            itemCount: upcoming.length,
            onReorderItem: (from, to) =>
                ctrl.reorderQueue(first + from, first + to),
            itemBuilder: (_, i) {
              final t = upcoming[i];
              return Dismissible(
                key: ValueKey(keys[i]),
                background: const DismissBackground(),
                secondaryBackground: const DismissBackground(alignEnd: true),
                onDismissed: (_) async {
                  await ctrl.removeFromQueue(first + i);
                  if (!context.mounted) return;
                  showUndoSnack(context, l.removedFromQueue, () {
                    ctrl.addToQueue(t.id);
                    ctrl.reorderQueue(queue.length - 1, first + i);
                  });
                },
                child: Material(
                  color: cc.surface1.withValues(alpha: 0),
                  child: SizedBox(
                    height: 64,
                    child: LiveTrackRow(
                      track: t,
                      variant: TrackRowVariant.queue,
                      reorderIndex: i,
                      onTap: () => ctrl.jumpToQueueIndex(first + i),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
