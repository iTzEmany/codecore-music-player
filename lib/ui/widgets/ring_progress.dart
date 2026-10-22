import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/player_providers.dart';
import '../theme/tokens.dart';

/// Playback fraction 0..1, or null when the duration is unknown.
double? ringProgress(Duration position, Duration? duration) {
  if (duration == null || duration <= Duration.zero) return null;
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

/// The cover inside an open ring (the app logo): the arc fills clockwise from
/// the gap and a dot marks the playhead. [live] (radio, Jam) paints it full.
class RingProgress extends ConsumerWidget {
  const RingProgress({
    super.key,
    required this.size,
    required this.child,
    this.live = false,
    this.stroke = 3,
  });

  final double size;
  final Widget child;
  final bool live;
  final double stroke;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    final inner = size - 2 * (stroke + 2);
    Widget paint(double? progress) => CustomPaint(
      size: Size.square(size),
      painter: RingPainter(
        progress: progress,
        arc: cc.accent,
        rest: cc.surface3,
        stroke: stroke,
      ),
    );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              live
                  ? paint(null)
                  : Consumer(
                      builder: (_, ref, _) => paint(
                        ringProgress(
                          ref.watch(positionProvider).value ?? Duration.zero,
                          ref.watch(durationProvider).value,
                        ),
                      ),
                    ),
              ClipOval(child: SizedBox.square(dimension: inner, child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Open ring with the gap at top right. [progress] null paints the whole arc
/// in [arc] with no dot.
class RingPainter extends CustomPainter {
  const RingPainter({
    required this.progress,
    required this.arc,
    required this.rest,
    required this.stroke,
  });

  final double? progress;
  final Color arc, rest;
  final double stroke;

  static const _gap = 40 * math.pi / 180;
  static const _sweep = 2 * math.pi - _gap;
  static const _start = -math.pi / 4 + _gap / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final dotR = stroke * 1.1;
    final r = size.shortestSide / 2 - dotR;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, line..color = rest);
    final p = progress;
    final played = _sweep * (p ?? 1);
    if (played > 0) canvas.drawArc(rect, _start, played, false, line..color = arc);
    if (p == null) return;
    final a = _start + played;
    canvas.drawCircle(
      c + Offset(math.cos(a), math.sin(a)) * r,
      dotR,
      Paint()..color = arc,
    );
  }

  @override
  bool shouldRepaint(RingPainter o) =>
      o.progress != progress || o.arc != arc || o.rest != rest || o.stroke != stroke;
}
