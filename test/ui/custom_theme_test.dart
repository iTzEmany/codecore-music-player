import 'dart:convert';

import 'package:codecore/ui/screens/settings/theme_editor_screen.dart';
import 'package:codecore/ui/theme/custom_theme.dart';
import 'package:codecore/ui/theme/palette.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Map<CcToken, Color> _all(CcColors c) => {
      CcToken.bg: c.bg,
      CcToken.surface1: c.surface1,
      CcToken.surface2: c.surface2,
      CcToken.surface3: c.surface3,
      CcToken.accent: c.accent,
      CcToken.accentSoft: c.accentSoft,
      CcToken.onAccent: c.onAccent,
      CcToken.text: c.text,
      CcToken.textMuted: c.textMuted,
      CcToken.textFaint: c.textFaint,
      CcToken.heroBase: c.heroBase,
      CcToken.error: c.error,
    };

void main() {
  group('resolve', () {
    test('a theme with nothing changed is its base, token for token', () {
      for (final id in AppThemeId.values) {
        final c = CustomTheme(id: 'a', name: 'A', base: id).resolve();
        final b = buildPalette(id, CcAccent.viola);
        expect(_all(c), _all(b), reason: id.name);
        expect(c.isLight, b.isLight);
      }
    });

    test('only the accent changed: the surfaces and texts stay, the accent-bound colours follow', () {
      const red = Color(0xFFE53935);
      final c = const CustomTheme(id: 'a', name: 'A').withColor(CcToken.accent, red).resolve();
      final b = buildPalette(AppThemeId.notte, CcAccent.viola);
      expect(c.accent, red);
      expect(c.bg, b.bg);
      expect(c.surface2, b.surface2);
      expect(c.text, b.text);
      expect(c.onAccent, onAccentFor(red));
      expect(c.accentSoft, accentSoftFor(red, false));
      expect(c.heroBase, heroFor(red, false));
    });

    test('a light background flips the theme: dark text, readable, surfaces step away from it', () {
      const cream = Color(0xFFF6EFD9);
      final c = const CustomTheme(id: 'a', name: 'A').withColor(CcToken.bg, cream).resolve();
      expect(c.isLight, isTrue);
      expect(contrastRatio(c.text, c.bg), greaterThanOrEqualTo(7));
      expect(contrastRatio(c.textMuted, c.bg), greaterThanOrEqualTo(3));
      expect(c.surface1.computeLuminance(), lessThan(c.bg.computeLuminance()));
      expect(c.surface3.computeLuminance(), lessThan(c.surface1.computeLuminance()));
      expect(c.surface1, isNot(c.bg));
    });

    test('a dark background gives light text and lighter surfaces', () {
      const navy = Color(0xFF0B1630);
      final c = const CustomTheme(id: 'a', name: 'A', base: AppThemeId.chiaro)
          .withColor(CcToken.bg, navy)
          .resolve();
      expect(c.isLight, isFalse);
      expect(contrastRatio(c.text, c.bg), greaterThanOrEqualTo(7));
      expect(c.surface1.computeLuminance(), greaterThan(c.bg.computeLuminance()));
      expect(c.surface3.computeLuminance(), greaterThan(c.surface1.computeLuminance()));
    });

    test('a colour set by hand wins over the derived one', () {
      const pink = Color(0xFFFF66AA);
      final c = const CustomTheme(id: 'a', name: 'A')
          .withColor(CcToken.bg, const Color(0xFF101010))
          .withColor(CcToken.surface1, pink)
          .withColor(CcToken.text, const Color(0xFFFFFF00))
          .resolve();
      expect(c.surface1, pink);
      expect(c.text, const Color(0xFFFFFF00));
      expect(c.textMuted, Color.lerp(c.text, c.bg, 0.35));
    });

    test('a colour is always opaque, and taking an override away restores the derived one', () {
      final t = const CustomTheme(id: 'a', name: 'A').withColor(CcToken.bg, const Color(0x80FFFFFF));
      expect(t.overrides[CcToken.bg]!.a, 1.0);
      expect(t.withoutColor(CcToken.bg).resolve().bg, CcColors.notte.bg);
    });
  });

  group('json', () {
    test('round trip keeps colours, base, name and background', () {
      final t = const CustomTheme(id: 'x1', name: 'Mare', base: AppThemeId.oled)
          .withColor(CcToken.bg, const Color(0xFF001122))
          .withColor(CcToken.accent, const Color(0xFF33CCAA))
          .copyWith(
            background: const ThemeBackground(
              kind: ThemeBackgroundKind.gradient,
              gradientEnd: Color(0xFF223344),
              angle: 90,
              dim: 0.5,
              blur: 4,
              coverBackdrop: false,
            ),
          );
      final back = CustomTheme.decode(t.encode())!;
      expect(back.id, 'x1');
      expect(back.name, 'Mare');
      expect(back.base, AppThemeId.oled);
      expect(back.overrides, t.overrides);
      expect(back.background, t.background);
      expect(_all(back.resolve()), _all(t.resolve()));
    });

    test('unknown tokens, non-integer colours, bad base and numbers out of range are tolerated', () {
      final t = CustomTheme.fromJson({
        'id': 'q',
        'name': '  ',
        'base': 'neon',
        'colors': {'bg': 0xFF112233, 'nope': 5, 'text': 'red', 'accent': 1.5},
        'background': {'kind': 'hologram', 'dim': 9, 'blur': -3, 'angle': 'x', 'gradientEnd': 'no'},
      })!;
      expect(t.name, 'Tema');
      expect(t.base, AppThemeId.notte);
      expect(t.overrides.keys, [CcToken.bg]);
      expect(t.background.kind, ThemeBackgroundKind.solid);
      expect(t.background.dim, 0.8);
      expect(t.background.blur, 0);
      expect(t.background.angle, 180);
      expect(t.background.gradientEnd, isNull);
    });

    test('something that is not a theme is null, never an exception', () {
      expect(CustomTheme.fromJson(null), isNull);
      expect(CustomTheme.fromJson({'name': 'no id'}), isNull);
      expect(CustomTheme.fromJson({'id': ''}), isNull);
      expect(CustomTheme.decode('not json {'), isNull);
      expect(CustomTheme.decode('[1,2]'), isNull);
    });
  });

  group('CustomThemes', () {
    CustomTheme t(String id) => CustomTheme(id: id, name: id);

    test('put adds, put with the same id replaces in place, remove drops', () {
      var l = const CustomThemes().put(t('a')).put(t('b'));
      expect([for (final x in l.items) x.id], ['a', 'b']);
      l = l.put(t('a').copyWith(name: 'A2'));
      expect([for (final x in l.items) x.name], ['A2', 'b']);
      expect(l.byId('b'), isNotNull);
      expect(l.byId('zz'), isNull);
      expect([for (final x in l.remove('a').items) x.id], ['b']);
    });

    test('a new one over the limit is refused, replacing one is still fine', () {
      var l = const CustomThemes();
      for (var i = 0; i < kMaxCustomThemes; i++) {
        l = l.put(t('t$i'));
      }
      expect(l.put(t('extra')).items, hasLength(kMaxCustomThemes));
      expect(l.put(t('t3').copyWith(name: 'x')).byId('t3')!.name, 'x');
    });

    test('decode skips damaged entries and repeated ids; a damaged list is empty', () {
      final raw = jsonEncode([
        t('a').toJson(),
        {'name': 'no id'},
        7,
        t('a').copyWith(name: 'again').toJson(),
        t('b').toJson(),
      ]);
      expect([for (final x in CustomThemes.decode(raw).items) x.id], ['a', 'b']);
      expect(CustomThemes.decode('garbage').items, isEmpty);
      expect(CustomThemes.decode('{"a":1}').items, isEmpty);
      expect(CustomThemes.decode(null).items, isEmpty);
      expect(CustomThemes.decode(CustomThemes([t('a')]).encode()).items.single.id, 'a');
    });

    test('the theme setting names a custom theme as custom:<id>', () {
      expect(customThemeSettingValue('abc'), 'custom:abc');
      expect(customThemeIdOf('custom:abc'), 'abc');
      expect(customThemeIdOf('notte'), isNull);
    });
  });

  group('ensureContrast', () {
    test('a colour that already reads is left alone', () {
      const c = Color(0xFFFFFFFF);
      expect(ensureContrast(c, const Color(0xFF000000)), c);
    });

    test('yellow on white gets darker until it reads, keeping its hue', () {
      const yellow = Color(0xFFFFEB3B);
      final fixed = ensureContrast(yellow, const Color(0xFFFFFFFF));
      expect(contrastRatio(fixed, const Color(0xFFFFFFFF)), greaterThanOrEqualTo(4.5));
      expect(HSLColor.fromColor(fixed).hue, closeTo(HSLColor.fromColor(yellow).hue, 6));
    });

    test('dark blue on black gets lighter', () {
      final fixed = ensureContrast(const Color(0xFF101040), const Color(0xFF000000));
      expect(contrastRatio(fixed, const Color(0xFF000000)), greaterThanOrEqualTo(4.5));
    });

    test('contrastRatio: black on white is 21, a colour on itself 1', () {
      expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
      expect(contrastRatio(const Color(0xFF336699), const Color(0xFF336699)), closeTo(1, 0.001));
    });
  });

  group('low contrast warning', () {
    test('bg #808080 warns and the colours stay those of the file', () {
      final t = CustomTheme(
        id: 'a',
        name: 'A',
        base: AppThemeId.notte,
        overrides: const {CcToken.bg: Color(0xFF808080)},
      );
      final c = CustomTheme.decode(t.encode())!.resolve();
      expect(c.bg, const Color(0xFF808080));
      expect(hasLowContrastText(c), isTrue);
      expect(hasLowContrastText(CustomTheme(id: 'b', name: 'B', base: AppThemeId.notte).resolve()), isFalse);
    });
  });
}
