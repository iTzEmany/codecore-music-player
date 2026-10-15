import 'package:audio_service/audio_service.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/ui/widgets/play_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('shuffle icon turns amethyst while shuffle is on',
      (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, Scaffold(body: ShuffleButton(onPressed: () {})));
    final cc = CcColors.notte;
    Color iconColor() =>
        tester.widget<Icon>(find.byIcon(Icons.shuffle_rounded)).color!;
    expect(iconColor(), cc.textMuted);

    await tester.runAsync(
        () => h.handler.setShuffleMode(AudioServiceShuffleMode.all));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(iconColor(), cc.accent);
    await h.dispose(tester);
  });
}
