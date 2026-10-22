import 'package:codecore/ui/screens/settings/advanced_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('advanced settings move the cut-offs and keep the gap; reset works',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: AdvancedSettingsTiles()));

    expect(find.text('Abbinamento sicuro da, 80%'), findsOneWidget);
    expect(find.text('Da verificare da, 55%'), findsOneWidget);

    // Dragging the «review» slider far right is held back by the «sure» one.
    await tester.drag(find.byType(Slider).last, const Offset(600, 0));
    await tester.pump(const Duration(milliseconds: 500));
    var s = h.store.readSettings();
    expect(s.importReviewThreshold, lessThanOrEqualTo(s.importSureThreshold - 0.049));

    await tester.tap(find.text('Ripristina i valori predefiniti'));
    await tester.pump(const Duration(milliseconds: 500));
    s = h.store.readSettings();
    expect(s.importSureThreshold, 0.80);
    expect(s.importReviewThreshold, 0.55);
    await h.dispose(tester);
  });
}
