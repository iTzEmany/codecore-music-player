import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/player_providers.dart';

class DebugPlayerBar extends ConsumerWidget {
  const DebugPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider).value;
    final playing = ref.watch(isPlayingProvider).value ?? false;
    final ctrl = ref.read(playerControllerProvider);
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(track?.title ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
          const _SeekSlider(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: ctrl.previous, icon: const Icon(Icons.skip_previous)),
            IconButton(
                onPressed: ctrl.togglePlayPause,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow)),
            IconButton(onPressed: ctrl.next, icon: const Icon(Icons.skip_next)),
          ]),
        ]),
      ),
    );
  }
}

class _SeekSlider extends ConsumerStatefulWidget {
  const _SeekSlider();

  @override
  ConsumerState<_SeekSlider> createState() => _SeekSliderState();
}

class _SeekSliderState extends ConsumerState<_SeekSlider> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value ?? Duration.zero;
    final max = dur.inMilliseconds.toDouble();
    final value = (_dragging ?? pos.inMilliseconds.toDouble()).clamp(0, max <= 0 ? 1 : max);
    return Slider(
      value: value.toDouble(),
      max: max <= 0 ? 1 : max,
      onChanged: max <= 0 ? null : (v) => setState(() => _dragging = v),
      onChangeEnd: (v) {
        setState(() => _dragging = null);
        ref.read(playerControllerProvider).seek(Duration(milliseconds: v.round()));
      },
    );
  }
}
