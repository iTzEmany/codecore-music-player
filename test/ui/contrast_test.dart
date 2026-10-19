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
  // Every built-in theme with every accent, through the same path as the app
  // (palette, then the theme built from it).
  for (final id in AppThemeId.values) {
    for (final accent in CcAccent.values) {
      final name = '${id.name} + ${accent.name}';
      test('$name: token pairs and scheme text colours meet WCAG AA', () {
        final theme = buildThemeFromColors(buildPalette(id, accent), false);
        final c = theme.extension<CcColors>()!;
        final s = theme.colorScheme;
        final pairs = {
          'text/bg': (c.text, c.bg, 4.5),
          'text/surface1': (c.text, c.surface1, 4.5),
          'text/surface2': (c.text, c.surface2, 4.5),
          'text/surface3': (c.text, c.surface3, 4.5),
          'textMuted/bg': (c.textMuted, c.bg, 4.5),
          'textMuted/surface1': (c.textMuted, c.surface1, 4.5),
          'textMuted/surface2': (c.textMuted, c.surface2, 4.5),
          // The playing row's title and links are drawn in the accent.
          'accent/bg': (c.accent, c.bg, 4.5),
          'accent/surface1': (c.accent, c.surface1, 3.0),
          'onAccent/accent': (c.onAccent, c.accent, 4.5),
          'accentSoft/surface1': (c.accentSoft, c.surface1, 4.5),
          'accentSoft/bg': (c.accentSoft, c.bg, 4.5),
          'error/bg': (c.error, c.bg, 4.5),
          'text/heroBase': (c.text, c.heroBase, 7.0),
          // What Material widgets draw with.
          'scheme onSurface/surface': (s.onSurface, s.surface, 4.5),
          'scheme onSurfaceVariant/surfaceContainerHigh':
              (s.onSurfaceVariant, s.surfaceContainerHigh, 4.5),
          'scheme onPrimary/primary': (s.onPrimary, s.primary, 4.5),
        };
        for (final e in pairs.entries) {
          expect(
            contrast(e.value.$1, e.value.$2),
            greaterThanOrEqualTo(e.value.$3),
            reason: '$name ${e.key}',
          );
        }
      });
    }
  }

  test('the light theme is light and the others are dark', () {
    Brightness of(AppThemeId id) =>
        buildThemeFromColors(buildPalette(id, CcAccent.viola), false).brightness;
    expect(of(AppThemeId.chiaro), Brightness.light);
    expect(of(AppThemeId.notte), Brightness.dark);
    expect(of(AppThemeId.oled), Brightness.dark);
    expect(buildPalette(AppThemeId.chiaro, CcAccent.blu).isLight, isTrue);
  });

  test('with the violet accent the palettes are the hand-picked ones', () {
    expect(buildPalette(AppThemeId.notte, CcAccent.viola), same(CcColors.notte));
    expect(buildPalette(AppThemeId.oled, CcAccent.viola), same(CcColors.oled));
    expect(buildPalette(AppThemeId.chiaro, CcAccent.viola), same(CcColors.chiaro));
  });

  test('another accent changes only the accent family', () {
    final v = buildPalette(AppThemeId.notte, CcAccent.viola);
    final b = buildPalette(AppThemeId.notte, CcAccent.blu);
    expect(b.accent, isNot(v.accent));
    expect(b.bg, v.bg);
    expect(b.text, v.text);
    expect(b.surface2, v.surface2);
  });

  test('every accent is different, on each theme', () {
    for (final id in AppThemeId.values) {
      final colors = {for (final a in CcAccent.values) buildPalette(id, a).accent};
      expect(colors, hasLength(CcAccent.values.length), reason: id.name);
    }
  });

  test('retired or unknown theme names fall back to notte; light is chiaro', () {
    for (final n in ['carbon', 'navy', '', 'boh']) {
      expect(appThemeIdFromName(n), AppThemeId.notte);
    }
    expect(appThemeIdFromName('light'), AppThemeId.chiaro);
    expect(appThemeIdFromName('chiaro'), AppThemeId.chiaro);
    expect(appThemeIdFromName('oled'), AppThemeId.oled);
    expect(appThemeIdFromName('notte'), AppThemeId.notte);
  });

  test('unknown accent names fall back to violet', () {
    expect(accentFromName('boh'), CcAccent.viola);
    expect(accentFromName(''), CcAccent.viola);
    expect(accentFromName('rosa'), CcAccent.rosa);
  });
}
