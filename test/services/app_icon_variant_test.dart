import 'package:codecore/services/app_icon/app_icon.dart';
import 'package:codecore/ui/theme/custom_theme.dart';
import 'package:codecore/ui/theme/palette.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const none = CustomThemes();

  test('built-in themes: Chiaro is light, Notte and OLED are dark, the accent is kept', () {
    for (final a in CcAccent.values) {
      expect(appIconVariantFor('chiaro', a.name, none), '${a.name}_light');
      expect(appIconVariantFor('notte', a.name, none), '${a.name}_dark');
      expect(appIconVariantFor('oled', a.name, none), '${a.name}_dark');
    }
  });

  test('a theme of the user picks the nearest accent and the ground of its background', () {
    final red = const CustomTheme(id: 'r', name: 'R')
        .withColor(CcToken.accent, const Color(0xFFE02020))
        .withColor(CcToken.bg, const Color(0xFFF6EFD9));
    final green = const CustomTheme(id: 'g', name: 'G').withColor(CcToken.accent, const Color(0xFF30C060));
    final customs = CustomThemes([red, green]);
    expect(appIconVariantFor('custom:r', 'viola', customs), 'rosso_light');
    expect(appIconVariantFor('custom:g', 'viola', customs), 'verde_dark');
  });

  test('a theme that no longer exists falls back to the built-in rule', () {
    expect(appIconVariantFor('custom:gone', 'blu', none), 'blu_dark');
  });
}
