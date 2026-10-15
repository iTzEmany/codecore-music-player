import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/player_providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../widgets/confirm.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/dismiss_background.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider).value ?? const [];
    final current = ref.watch(currentTrackProvider).value?.id;
    final ctrl = ref.read(playerControllerProvider);
    if (queue.isEmpty) {
      return Center(child: Text(context.l10n.emptyQueue));
    }
    final seen = <int, int>{};
    final keys = [
      for (final t in queue) 'q-${t.id}-${seen[t.id] = (seen[t.id] ?? -1) + 1}'
    ];
    return ReorderableListView.builder(
      scrollController: scrollController,
      itemCount: queue.length,
      onReorderItem: ctrl.reorderQueue,
      itemBuilder: (_, i) {
        final t = queue[i];
        return Dismissible(
          // Stable per entry: the same track may sit twice in the queue.
          key: ValueKey(keys[i]),
          background: const DismissBackground(),
          secondaryBackground: const DismissBackground(alignEnd: true),
          onDismissed: (_) async {
            await ctrl.removeFromQueue(i);
            if (!context.mounted) return;
            showUndoSnack(context, context.l10n.removedFromQueue, () {
              ctrl.addToQueue(t.id);
              ctrl.reorderQueue(queue.length - 1, i);
            });
          },
          child: ListTile(
            leading: CoverImage(coverKey: t.coverKey, size: 40),
            title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(t.artist ?? '', maxLines: 1),
            selected: t.id == current,
            onTap: () => ctrl.jumpToQueueIndex(i),
          ),
        );
      },
    );
  }
}
