import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/listen_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/online/download_queue.dart';
import '../../../services/online/youtube_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';
import 'online_results.dart' show ytErrorText;

/// «Ascolta» on a result row: plays it, then pauses and resumes it.
class ListenButton extends ConsumerWidget {
  const ListenButton({super.key, required this.result});

  final YtResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final phase = ref.watch(
      listenProvider.select((s) => s.isOf(result) ? s.phase : ListenPhase.idle),
    );
    if (phase == ListenPhase.resolving) {
      return SizedBox(
        width: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              semanticsLabel: l.listenResolving,
            ),
          ),
        ),
      );
    }
    final (icon, tip) = switch (phase) {
      ListenPhase.playing => (Icons.pause_rounded, l.pause),
      ListenPhase.paused => (Icons.play_arrow_rounded, l.play),
      _ => (Icons.headphones_rounded, l.listenAction),
    };
    return IconButton(
      key: ValueKey('listen-${result.indexKey}'),
      tooltip: tip,
      icon: Icon(icon),
      onPressed: () => ref.read(listenProvider.notifier).toggle(result),
    );
  }
}

/// The result being listened to, under the results: progress, pause, download
/// and close. Nothing while no listen is on.
class ListenBar extends ConsumerWidget {
  const ListenBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(listenProvider);
    final r = s.result;
    return AnimatedSwitcher(
      duration: ccDuration(context, CcMotion.sheet),
      transitionBuilder: (child, a) => SizeTransition(
        sizeFactor: a,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: a, child: child),
      ),
      child: !s.active || r == null
          ? const SizedBox(width: double.infinity)
          : _Bar(state: s, result: r),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.state, required this.result});

  final ListenState state;
  final YtResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final notifier = ref.read(listenProvider.notifier);
    final total = state.duration ?? result.duration;
    final progress =
        state.phase == ListenPhase.resolving ||
            total == null ||
            total == Duration.zero
        ? null
        : (state.position.inMilliseconds / total.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    final downloading = ref.watch(
      downloadsProvider.select(
        (d) => d.any(
          (i) =>
              i.result.indexKey == result.indexKey &&
              (i.status == DownloadStatus.queued ||
                  i.status == DownloadStatus.downloading ||
                  i.status == DownloadStatus.waitingRetry),
        ),
      ),
    );
    final inLibrary = ref.watch(
      downloadIndexProvider.select(
        (i) => i.value?.contains(result.id, source: result.source) ?? false,
      ),
    );
    return Material(
      key: const ValueKey('listen-bar'),
      color: cc.surface2,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress, minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, 4, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.headphones_rounded,
                    color: cc.accentSoft,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          result.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyLarge,
                        ),
                        Text(
                          state.phase == ListenPhase.resolving
                              ? l.listenResolving
                              : [
                                  result.channel,
                                  if (total != null)
                                    '${formatDuration(state.position.inMilliseconds)} / '
                                        '${formatDuration(total.inMilliseconds)}',
                                ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Fixed slots (48 px each) in every state: the buttons never
                  // move, so a tap meant for «Chiudi» cannot land on «Scarica».
                  if (state.phase == ListenPhase.resolving)
                    const SizedBox(width: 48, height: 48)
                  else
                    IconButton(
                      tooltip: state.phase == ListenPhase.playing
                          ? l.pause
                          : l.play,
                      icon: Icon(
                        state.phase == ListenPhase.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: state.phase == ListenPhase.playing
                          ? notifier.pause
                          : notifier.resume,
                    ),
                  if (inLibrary)
                    const SizedBox(width: 48, height: 48)
                  else
                    IconButton(
                      tooltip: l.ytDownload,
                      icon: downloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      onPressed: downloading
                          ? null
                          : () => ref
                                .read(downloadsProvider.notifier)
                                .add(result),
                    ),
                  IconButton(
                    tooltip: l.close,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: notifier.stop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tells why an «Ascolta» failed, wherever the user is (results, artist page,
/// suggestions...): the bar vanishing silently looked like a hang.
class ListenErrorToaster extends ConsumerWidget {
  const ListenErrorToaster({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(listenProvider.select((s) => s.error), (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(ytErrorText(context, error))));
    });
    return child;
  }
}
