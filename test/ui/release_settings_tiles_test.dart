import 'package:codecore/ui/screens/settings/release_settings_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/releases_support.dart';

void main() {
  testWidgets('the switches write the options; «Solo su Wi‑Fi» is off by default', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final checks = FakeChecks(h.db, h.store);
    await h.pump(tester, const Scaffold(body: ReleaseSettingsTiles()), extraOverrides: [checks.override]);
    expect(h.store.releasesUnmeteredOnly, isFalse);
    expect(find.text('Segui in automatico i più ascoltati'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('releases-unmetered')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.store.releasesUnmeteredOnly, isTrue);
    await h.dispose(tester);
    checks.dispose();
  });
}
