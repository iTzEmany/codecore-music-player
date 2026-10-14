import 'dart:math';

import 'package:codecore/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
}

void main() {
  for (final id in AppThemeId.values) {
    test('${id.name}: text colours meet WCAG AA (4.5:1)', () {
      final s = buildTheme(id, false).colorScheme;
      final pairs = {
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'primary/surface': (s.primary, s.surface),
        'onSurface/surfaceContainerHigh': (s.onSurface, s.surfaceContainerHigh),
        'onSurfaceVariant/surfaceContainerHigh':
            (s.onSurfaceVariant, s.surfaceContainerHigh),
        'onPrimary/primary': (s.onPrimary, s.primary),
      };
      for (final e in pairs.entries) {
        expect(contrast(e.value.$1, e.value.$2), greaterThanOrEqualTo(4.5),
            reason: '${id.name} ${e.key}');
      }
    });
  }
}
