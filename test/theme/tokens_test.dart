import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('oled differs from notte only by the background', () {
    final o = CcColors.oled, n = CcColors.notte;
    expect(o.bg, Colors.black);
    for (final pair in [
      (o.surface1, n.surface1), (o.surface2, n.surface2), (o.surface3, n.surface3),
      (o.accent, n.accent), (o.accentSoft, n.accentSoft), (o.onAccent, n.onAccent),
      (o.text, n.text), (o.textMuted, n.textMuted), (o.textFaint, n.textFaint),
      (o.heroBase, n.heroBase), (o.error, n.error),
    ]) {
      expect(pair.$1, pair.$2);
    }
    expect(o.isLight, n.isLight);
  });
}
