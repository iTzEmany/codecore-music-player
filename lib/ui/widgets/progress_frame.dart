import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/player_providers.dart';
import '../theme/tokens.dart';

/// Rounded-square 2 dp frame (track in the separator colour, arc in the
/// accent) that runs clockwise from the top-left corner (D-25). [progress]
/// null = full frame (a state, not the playhead). Paints over [child], or
/// alone when it has none (then it fills the space it gets).
class ProgressFrame extends StatelessWidget {
  const ProgressFrame({super.key, this.child, this.progress, this.size});

  final Widget? child;
  final double? progress;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        foregroundPainter: _FramePainter(
          (progress ?? 1).clamp(0.0, 1.0),
          cc.accent,
          cc.separator,
        ),
        child: child,
      ),
    );
  }
}

/// A [ProgressFrame] that follows the playhead of the current track.
class LiveProgressFrame extends ConsumerWidget {
  const LiveProgressFrame({super.key, this.child, this.size});

  final Widget? child;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value;
    final progress = dur == null || dur <= Duration.zero
        ? 0.0
        : pos.inMilliseconds / dur.inMilliseconds;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: ProgressFrame(progress: progress, size: size, child: child),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.fraction, this.arc, this.rest);

  final double fraction;
  final Color arc, rest;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(7),
        ),
      );
    if (fraction < 1) canvas.drawPath(path, line..color = rest);
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * fraction), line..color = arc);
    }
  }

  @override
  bool shouldRepaint(_FramePainter o) =>
      o.fraction != fraction || o.arc != arc || o.rest != rest;
}
