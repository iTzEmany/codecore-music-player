import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Bars of the time played in each day or month, drawn by hand: no package.
/// [labels] gives the text under some of the bars (null = none).
class StatsBars extends StatelessWidget {
  const StatsBars({
    super.key,
    required this.values,
    required this.labelOf,
    this.semanticsLabel,
  });

  final List<int> values;
  final String? Function(int index) labelOf;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: cc.textMuted);
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: SizedBox(
        height: 150,
        child: CustomPaint(
          size: Size.infinite,
          painter: _BarsPainter(
            values: values,
            color: cc.accent,
            emptyColor: cc.surface3,
            labels: [for (var i = 0; i < values.length; i++) labelOf(i)],
            labelStyle: style ?? const TextStyle(),
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.color,
    required this.emptyColor,
    required this.labels,
    required this.labelStyle,
    required this.textDirection,
  });

  final List<int> values;
  final Color color, emptyColor;
  final List<String?> labels;
  final TextStyle labelStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelBand = 18.0;
    final plotH = size.height - labelBand;
    final peak = values.reduce((a, b) => a > b ? a : b);
    final slot = size.width / values.length;
    final barW = (slot * 0.62).clamp(2.0, 28.0);
    for (var i = 0; i < values.length; i++) {
      final x = slot * i + (slot - barW) / 2;
      // A day with nothing played still shows a stub, so the axis reads.
      final h = peak == 0 || values[i] == 0
          ? 3.0
          : (values[i] / peak * (plotH - 4)).clamp(3.0, plotH);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, plotH - h, barW, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = values[i] == 0 ? emptyColor : color,
      );
      final text = labels[i];
      if (text != null) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: labelStyle),
          textDirection: textDirection,
        )..layout();
        tp.paint(canvas, Offset(slot * i + (slot - tp.width) / 2, plotH + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values ||
      old.color != color ||
      old.emptyColor != emptyColor ||
      old.labels != labels;
}
