import 'package:codecore/ui/widgets/speed_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('the chip shows the speed and the sheet changes it',
      (tester) async {
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: Center(child: SpeedButton())));
    expect(find.text('1×'), findsOneWidget);

    await tester.tap(find.text('1×'));
    await tester.pumpAndSettle();
    expect(find.text('Velocità di riproduzione'), findsWidgets);
    for (final v in ['0,5×', '0,75×', '1,25×', '1,5×', '1,75×', '2×']) {
      expect(find.text(v), findsOneWidget, reason: v);
    }
    await tester.tap(find.text('1,5×'));
    await tester.pumpAndSettle();

    expect(h.store.readSettings().playbackSpeed, 1.5);
    expect(find.text('1,5×'), findsOneWidget, reason: 'the chip now says 1,5×');
    await h.dispose(tester);
  });
}
