import 'dart:math';

import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
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
    test('${id.name}: token pairs meet WCAG AA (4.5:1)', () {
      final c = buildTheme(id, false).extension<CcColors>()!;
      final pairs = {
        'text/bg': (c.text, c.bg),
        'text/surface1': (c.text, c.surface1),
        'text/surface2': (c.text, c.surface2),
        'textMuted/bg': (c.textMuted, c.bg),
        'textMuted/surface1': (c.textMuted, c.surface1),
        'textMuted/surface2': (c.textMuted, c.surface2),
        'accent/bg': (c.accent, c.bg),
        'onAccent/accent': (c.onAccent, c.accent),
        'accentSoft/surface1': (c.accentSoft, c.surface1),
        'error/bg': (c.error, c.bg),
      };
      for (final e in pairs.entries) {
        expect(contrast(e.value.$1, e.value.$2), greaterThanOrEqualTo(4.5),
            reason: '${id.name} ${e.key}');
      }
    });

    test('${id.name}: scheme text colours stay readable', () {
      final s = buildTheme(id, false).colorScheme;
      expect(contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(s.onSurfaceVariant, s.surfaceContainerHigh),
          greaterThanOrEqualTo(4.5));
      expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
    });
  }

  test('retired or unknown theme names fall back to notte', () {
    for (final n in ['carbon', 'navy', 'light', '', 'boh']) {
      expect(appThemeIdFromName(n), AppThemeId.notte);
    }
    expect(appThemeIdFromName('oled'), AppThemeId.oled);
    expect(appThemeIdFromName('notte'), AppThemeId.notte);
  });
}
