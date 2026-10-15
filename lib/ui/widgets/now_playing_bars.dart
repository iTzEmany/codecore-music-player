import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Three bars: animated while [playing], still otherwise or with
/// «Riduci animazioni».
class NowPlayingBars extends StatefulWidget {
  const NowPlayingBars({super.key, required this.playing, this.size = 18});

  final bool playing;
  final double size;

  @override
  State<NowPlayingBars> createState() => _NowPlayingBarsState();
}

class _NowPlayingBarsState extends State<NowPlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  bool _animate(BuildContext context) =>
      widget.playing && !MediaQuery.disableAnimationsOf(context);

  void _sync(BuildContext context) {
    if (_animate(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(context);
  }

  @override
  void didUpdateWidget(NowPlayingBars old) {
    super.didUpdateWidget(old);
    _sync(context);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.cc.accent;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _BarsPainter(_c, color),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.t, this.color) : super(repaint: t);

  final Animation<double> t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width / 5;
    const phases = [0.0, 0.33, 0.66];
    for (var i = 0; i < 3; i++) {
      final v = t.isAnimating || t.value > 0
          ? 0.35 + 0.65 * (0.5 + 0.5 * _wave(t.value + phases[i]))
          : const [0.55, 0.9, 0.7][i];
      final h = size.height * v;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(i * w * 2, size.height - h, w, h),
            Radius.circular(w / 2)),
        paint,
      );
    }
  }

  static double _wave(double x) {
    final f = (x % 1.0) * 2 - 1;
    return 1 - 2 * f.abs();
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.color != color;
}
