import 'dart:math';
import 'dart:typed_data';

import 'package:codecore/ui/theme/cover_tint.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _solid(int r, int g, int b, {int n = 16}) => Uint8List.fromList([
      for (var i = 0; i < n; i++) ...[r, g, b, 255]
    ]);

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
}

void main() {
  test('red cover gives a red tint', () {
    final t = tintFromPixels(_solid(220, 30, 40))!;
    expect(t.r, greaterThan(t.g));
    expect(t.r, greaterThan(t.b));
  });

  test('black, white and transparent pixels give no tint', () {
    expect(tintFromPixels(_solid(0, 0, 0)), isNull);
    expect(tintFromPixels(_solid(255, 255, 255)), isNull);
    expect(tintFromPixels(Uint8List.fromList([200, 10, 10, 0, 200, 10, 10, 0])),
        isNull);
  });

  test('saturated pixels weigh more than grey ones', () {
    final mix = Uint8List.fromList([
      ...List.generate(8, (_) => [128, 128, 128, 255]).expand((e) => e),
      ...List.generate(2, (_) => [220, 20, 20, 255]).expand((e) => e),
    ]);
    final t = tintFromPixels(mix)!;
    expect(t.r, greaterThan(t.g + 0.1));
  });

  test('heroTint keeps lightness in range and text contrast ≥ 7', () {
    final base = CcColors.notte.heroBase;
    for (final c in [
      const Color(0xFFFF0000),
      const Color(0xFFFFFF00),
      const Color(0xFF00FFFF),
      const Color(0xFFFFFFFF),
      const Color(0xFF101010),
    ]) {
      final t = heroTint(c, base);
      final l = HSLColor.fromColor(t).lightness;
      expect(l, lessThanOrEqualTo(0.301));
      expect(_contrast(CcColors.notte.text, t), greaterThanOrEqualTo(7));
    }
  });
}
