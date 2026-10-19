import 'package:codecore/services/backup/restore_service.dart';
import 'package:codecore/ui/screens/settings/restore_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

RestorePlan plan({required bool same}) => RestorePlan(
    createdAt: DateTime(2026, 10, 19, 12).millisecondsSinceEpoch,
    appVersion: '1.2.0', platform: 'linux', schemaVersion: 10, trackCount: 120, playlistCount: 4, sameDevice: same);

/// Opens the dialog; the returned function gives what it closed with.
Future<RestoreChoice? Function()> open(WidgetTester tester, Harness h, RestorePlan p) async {
  RestoreChoice? result;
  await h.pump(
    tester,
    Builder(builder: (c) => TextButton(
        onPressed: () async => result = await showDialog<RestoreChoice>(context: c, builder: (_) => RestoreDialog(plan: p)),
        child: const Text('open'))),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

void main() {
  testWidgets('same device: both choices, with what the backup holds', (tester) async {
    final h = await Harness.create(tester);
    await open(tester, h, plan(same: true));
    expect(find.textContaining('120 brani'), findsOneWidget);
    expect(find.textContaining('4 playlist'), findsOneWidget);
    expect(find.text('Sostituisci tutto (stesso dispositivo)'), findsOneWidget);
    expect(find.text('Unisci a questa libreria'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('another device: «Sostituisci» is not there; Merge returns its choice', (tester) async {
    final h = await Harness.create(tester);
    final result = await open(tester, h, plan(same: false));
    expect(find.text('Sostituisci tutto (stesso dispositivo)'), findsNothing);
    await tester.tap(find.text('Unisci a questa libreria'));
    await tester.pumpAndSettle();
    expect(result(), RestoreChoice.merge);
    await h.dispose(tester);
  });
}
