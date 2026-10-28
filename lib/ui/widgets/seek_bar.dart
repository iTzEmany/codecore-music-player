import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'format_utils.dart';

/// Fraction (0..1) under the finger while the ring or the bar is dragged (null
/// otherwise): both draw it and the elapsed time follows it. The seek itself
/// happens on release.
final seekDragProvider = NotifierProvider<SeekDrag, double?>(SeekDrag.new);

class SeekDrag extends Notifier<double?> {
  @override
  double? build() => null;

  void set(double? f) => state = f;
}

/// Horizontal seek slider: follows [position] (the one source the ring and the
/// times use too), shows the shared drag while dragging and calls [onSeek]
/// only on release. Disabled while [duration] is unknown.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final ValueListenable<Duration> position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  late final SeekDrag _drag = ref.read(seekDragProvider.notifier);
  bool _active = false;

  @override
  void dispose() {
    // Closed mid-drag: the elapsed time must not stay on the finger.
    if (_active) Future.microtask(() => _drag.set(null));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble();
    final top = max > 0 ? max : 1.0;
    final drag = ref.watch(seekDragProvider);
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.position,
      builder: (_, pos, _) => Slider(
        // Unknown duration: the knob rests at the start.
        value: max <= 0
            ? 0.0
            : (drag != null ? drag * top : pos.inMilliseconds.toDouble())
                  .clamp(0.0, top),
        max: top,
        onChanged: max <= 0
            ? null
            : (v) {
                _active = true;
                _drag.set(v / max);
              },
        onChangeEnd: (v) {
          _active = false;
          _drag.set(null);
          widget.onSeek(Duration(milliseconds: v.round()));
        },
      ),
    );
  }
}

/// Elapsed time (or, with [remaining], the time left) on the same source as
/// the bar and the ring: the finger while dragging, else [position].
class SeekTime extends ConsumerWidget {
  const SeekTime({
    super.key,
    required this.position,
    required this.duration,
    this.remaining = false,
    this.style,
  });

  final ValueListenable<Duration> position;
  final Duration duration;
  final bool remaining;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drag = ref.watch(seekDragProvider);
    return ValueListenableBuilder<Duration>(
      valueListenable: position,
      builder: (_, pos, _) {
        final shown = drag != null ? duration * drag : pos;
        final left = duration - shown;
        return Text(
          remaining
              ? '-${formatDuration(left.isNegative ? 0 : left.inMilliseconds)}'
              : formatDuration(shown.inMilliseconds),
          style: style,
        );
      },
    );
  }
}
