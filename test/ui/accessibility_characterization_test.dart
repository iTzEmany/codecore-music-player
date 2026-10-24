// What the app does TODAY with system accessibility flags and at 200 % text
// (38.6). Defects are pinned as known; D-14 / phase 40 change them and update
// these tests in the same step.
import 'package:codecore/app.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/ui/screens/car/car_mode_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void _phone(WidgetTester tester, {double scale = 1}) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<Harness> _playing(WidgetTester tester) async {
  final h = await Harness.create(tester, tracks: 3);
  final ids = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!
      .map((t) => t.id)
      .toList();
  await tester.runAsync(() => h.handler.playQueue(ids, 0));
  return h;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('KNOWN DEFECT (D-14): the system flags are ignored', (tester) async {
    _phone(tester, scale: 2.0);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = await Harness.create(tester, tracks: 1);
    await tester.pumpWidget(
        ProviderScope(overrides: h.overrides, child: const CodecoreApp()));
    await tester.pump(const Duration(milliseconds: 600));
    final mq = MediaQuery.of(tester.element(find.byType(AppShell)));
    // The system asks for 2x text and no animations; the app follows only
    // its own settings (defaults: scale 1, motion on).
    expect(mq.disableAnimations, isFalse);
    expect(mq.textScaler.scale(10), 10);
    final c = ProviderScope.containerOf(tester.element(find.byType(CodecoreApp)));
    expect(c.read(settingsProvider).reducedMotion, isFalse);
    expect(c.read(settingsProvider).fontScale, 1.0);
    await h.dispose(tester);
  });

  testWidgets('mini player and dock at 200 %: KNOWN DEFECT, the mini player overflows',
      (tester) async {
    _phone(tester);
    final h = await _playing(tester);
    await h.pump(tester, const AppShell(), textScale: 2.0);
    await _settle(tester);
    // The text column of the mini player is taller than its 56 px bar.
    final errors = <String>[];
    Object? e;
    while ((e = tester.takeException()) != null) {
      errors.add(e.toString());
    }
    expect(errors, isNotEmpty);
    expect(errors, everyElement(contains('overflowed')));
    // Still usable: the dock and the current title are on screen.
    expect(find.text('Song 0'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('car mode at 200 %: no overflow, controls stay big', (tester) async {
    _phone(tester, scale: 2.0);
    final h = await _playing(tester);
    await h.pump(tester, const CarModeScreen());
    await _settle(tester);
    expect(tester.takeException(), isNull);
    for (final tip in ['Brano precedente', 'Brano successivo', 'Pausa']) {
      final box = tester.getSize(
          find.ancestor(of: find.byTooltip(tip), matching: find.byType(SizedBox)).first);
      expect(box.shortestSide, greaterThanOrEqualTo(96), reason: tip);
    }
    await h.dispose(tester);
  });
}
