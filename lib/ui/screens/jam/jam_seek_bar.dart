import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/jam/jam_models.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';

/// Shared position slider with elapsed / total, with its own timer: only
/// this widget rebuilds every 500 ms, not the whole Jam screen.
class JamSeekBar extends StatefulWidget {
  const JamSeekBar({super.key, required this.jam, required this.onSeek});

  final JamState jam;
  final void Function(int positionMs) onSeek;

  @override
  State<JamSeekBar> createState() => _JamSeekBarState();
}

class _JamSeekBarState extends State<JamSeekBar> {
  Timer? _tick;
  double? _dragging;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _dragging == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jam = widget.jam;
    final cur = jam.current;
    final dur = (cur?.durationMs ?? 0).toDouble();
    final max = dur > 0 ? dur : 1.0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final pos = (_dragging ?? jam.positionAtTime(now).toDouble())
        .clamp(0.0, max)
        .toDouble();
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: context.cc.textMuted);
    return Column(
      children: [
        Slider(
          value: pos,
          max: max,
          onChanged: cur == null || dur <= 0
              ? null
              : (v) => setState(() => _dragging = v),
          onChangeEnd: (v) {
            setState(() => _dragging = null);
            widget.onSeek(v.round());
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(pos.round()), style: style),
              Text(formatDuration(dur.round()), style: style),
            ],
          ),
        ),
      ],
    );
  }
}
