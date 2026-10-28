import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/jam/jam_models.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/seek_bar.dart';
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
  // Own drag state: the Jam's clock is not the local player's (ring, times).
  final _scope = [seekDragProvider.overrideWith(SeekDrag.new)];

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
    final dur = Duration(milliseconds: widget.jam.current?.durationMs ?? 0);
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: context.cc.textMuted);
    return ProviderScope(
      overrides: _scope,
      child: Column(
        children: [
          SeekBar(
            position: _smooth,
            duration: dur,
            onSeek: (d) => widget.onSeek(d.inMilliseconds),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CcDims.gap16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SeekTime(position: _smooth, duration: dur, style: style),
                Text(formatDuration(dur.inMilliseconds), style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
