import 'package:flutter/material.dart';

import '../../../services/jam/jam_models.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/smooth_position.dart';

/// Shared position slider with elapsed / total, on its own [SmoothPosition]:
/// only this widget rebuilds on a tick, not the whole Jam screen.
class JamSeekBar extends StatefulWidget {
  const JamSeekBar({super.key, required this.jam, required this.onSeek});

  final JamState jam;
  final void Function(int positionMs) onSeek;

  @override
  State<JamSeekBar> createState() => _JamSeekBarState();
}

class _JamSeekBarState extends State<JamSeekBar> {
  final _smooth = SmoothPosition();
  double? _dragging;

  // SmoothPosition advances it between Jam states.
  void _feed() {
    final jam = widget.jam;
    _smooth.update(
      Duration(
        milliseconds: jam.positionAtTime(DateTime.now().millisecondsSinceEpoch),
      ),
      playing: jam.playing && jam.current != null,
      duration: Duration(milliseconds: jam.current?.durationMs ?? 0),
    );
  }

  @override
  void initState() {
    super.initState();
    _feed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _smooth.bindTickerMode(context);
  }

  @override
  void didUpdateWidget(JamSeekBar old) {
    super.didUpdateWidget(old);
    if (old.jam != widget.jam) _feed();
  }

  @override
  void dispose() {
    _smooth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jam = widget.jam;
    final cur = jam.current;
    final dur = (cur?.durationMs ?? 0).toDouble();
    final max = dur > 0 ? dur : 1.0;
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: context.cc.textMuted);
    return ValueListenableBuilder<Duration>(
      valueListenable: _smooth,
      builder: (context, smooth, _) {
        final pos = (_dragging ?? smooth.inMilliseconds.toDouble())
            .clamp(0.0, max)
            .toDouble();
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
              padding: const EdgeInsets.symmetric(horizontal: CcDims.gap16),
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
      },
    );
  }
}
