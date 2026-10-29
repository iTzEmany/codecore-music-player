import 'package:codecore/providers/speaker_providers.dart';
import 'package:codecore/services/audio/bluetooth_outputs.dart';
import 'package:codecore/services/audio/speaker_monitor.dart';
import 'package:codecore/ui/screens/jam/speaker_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

Future<SpeakerMonitor> _pump(WidgetTester t, Harness h, SpeakerPrompt p, bool Function() requested) async {
  SharedPreferences.setMockInitialValues({});
  final m = SpeakerMonitor(
    fetch: () async => const BluetoothSnapshot(permission: false),
    changed: const Stream.empty(),
    seen: const Stream.empty(),
    active: () async => false,
    request: () async {
      return requested();
    },
  );
  await m.start();
  await h.pump(
    t,
    Builder(
      builder: (c) => Scaffold(
        body: TextButton(onPressed: () => showSpeakerPrompt(c, p), child: const Text('open')),
      ),
    ),
    extraOverrides: [speakerMonitorProvider.overrideWithValue(m)],
  );
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return m;
}

void main() {
  testWidgets('permission sheet: Consenti asks the system and saves «chiesto»', (t) async {
    final h = await Harness.create(t);
    var asked = false;
    final m = await _pump(t, h, const PermissionPrompt(), () => asked = true);
    expect(find.text('Permesso Bluetooth'), findsOneWidget);
    await t.tap(find.text('Consenti'));
    await t.pumpAndSettle();
    expect(asked, isTrue);
    expect(m.permissionAsked, isTrue);
    expect(find.text('Permesso Bluetooth'), findsNothing);
    await h.dispose(t);
  });

  testWidgets('permission sheet: Non ora saves «chiesto» without asking', (t) async {
    final h = await Harness.create(t);
    var asked = false;
    final m = await _pump(t, h, const PermissionPrompt(), () => asked = true);
    await t.tap(find.text('Non ora'));
    await t.pumpAndSettle();
    expect(asked, isFalse);
    expect(m.permissionAsked, isTrue);
    await h.dispose(t);
  });

  testWidgets('«È una cassa?»: Sì saves the answer with the name', (t) async {
    final h = await Harness.create(t);
    final m = await _pump(
      t,
      h,
      const AskPrompt(BluetoothOutput(name: 'JBL Flip', address: 'aa', deviceClass: 0x0418)),
      () => true,
    );
    expect(find.text('JBL Flip è una cassa?'), findsOneWidget);
    await t.tap(find.text('Sì'));
    await t.pumpAndSettle();
    expect(m.answers['aa']!.isSpeaker, isTrue);
    expect(m.answers['aa']!.name, 'JBL Flip');
    await h.dispose(t);
  });

  testWidgets('«È una cassa?»: No saves a no', (t) async {
    final h = await Harness.create(t);
    final m = await _pump(
      t,
      h,
      const AskPrompt(BluetoothOutput(name: 'Auto', address: 'bb')),
      () => true,
    );
    await t.tap(find.text('No'));
    await t.pumpAndSettle();
    expect(m.answers['bb']!.isSpeaker, isFalse);
    await h.dispose(t);
  });
}
