import 'package:codecore/services/backup/restore_service.dart';
import 'package:codecore/ui/screens/settings/restore_dialog.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

RestorePlan plan({required bool same}) => RestorePlan(
    createdAt: DateTime(2026, 10, 19, 12).millisecondsSinceEpoch,
    appVersion: '1.2.0', platform: 'linux', schemaVersion: 10, trackCount: 120, playlistCount: 4, sameDevice: same);

Future<RestoreChoice?> open(WidgetTester tester, Harness h, RestorePlan p, String tap) async {
  RestoreChoice? result;
  await h.pump(
    tester,
    Builder(builder: (c) => TextButton(
        onPressed: () async => result = await showDialog<RestoreChoice>(context: c, builder: (_) => RestoreDialog(plan: p)),
        child: const Text('open'))),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  if (tap.isNotEmpty) {
    await tester.tap(find.text(tap));
    await tester.pumpAndSettle();
  }
  return result;
}

void main() {
  testWidgets('same device: both choices, with what the backup holds', (tester) async {
    final h = await Harness.create(tester);
    final r = await open(tester, h, plan(same: true), '');
    expect(r, isNull);
    expect(find.textContaining('120 brani'), findsOneWidget);
    expect(find.textContaining('4 playlist'), findsOneWidget);
    expect(find.text('Sostituisci tutto (stesso dispositivo)'), findsOneWidget);
    expect(find.text('Unisci a questa libreria'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('another device: «Sostituisci» is not there; Merge returns its choice', (tester) async {
    final h = await Harness.create(tester);
    await open(tester, h, plan(same: false), '');
    expect(find.text('Sostituisci tutto (stesso dispositivo)'), findsNothing);
    await tester.tap(find.text('Unisci a questa libreria'));
    await tester.pumpAndSettle();
    await h.dispose(tester);
  });

  testWidgets('Settings has a Backup group with both entries', (tester) async {
    tester.view.physicalSize = const Size(500, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: SettingsScreen()));
    expect(find.text('Crea backup'), findsOneWidget);
    expect(find.text('Ripristina da backup'), findsWidgets);
    await h.dispose(tester);
  });
}
