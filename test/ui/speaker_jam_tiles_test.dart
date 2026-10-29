import 'package:codecore/providers/speaker_providers.dart';
import 'package:codecore/services/audio/bluetooth_outputs.dart';
import 'package:codecore/services/audio/speaker_monitor.dart';
import 'package:codecore/ui/screens/settings/speaker_jam_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

void main() {
  Future<SpeakerMonitor> pump(WidgetTester t, Harness h, {bool permission = true, Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    var requests = 0;
    final m = SpeakerMonitor(
      fetch: () async => BluetoothSnapshot(permission: permission),
      changed: const Stream.empty(),
      seen: const Stream.empty(),
      active: () async => false,
      request: () async => ++requests > 0,
    );
    await m.start();
    await h.pump(
      t,
      const Scaffold(body: SingleChildScrollView(child: SpeakerJamTiles())),
      extraOverrides: [speakerMonitorProvider.overrideWithValue(m)],
    );
    return m;
  }

  testWidgets('switch is on by default and turns off', (t) async {
    final h = await Harness.create(t);
    final m = await pump(t, h);
    expect(find.text('Nessun dispositivo segnato finora'), findsOneWidget);
    expect(m.enabled, isTrue);
    await t.tap(find.byType(Switch).first);
    await t.pumpAndSettle();
    expect(m.enabled, isFalse);
    await h.dispose(t);
  });

  testWidgets('lists the marked devices and changes one', (t) async {
    final h = await Harness.create(t);
    final m = await pump(t, h, prefs: {
      'speakerJam.answers': '{"aa":{"n":"JBL Flip","s":true},"bb":{"n":"Auto","s":false}}',
    });
    expect(find.text('JBL Flip'), findsOneWidget);
    expect(find.text('Cassa'), findsOneWidget);
    expect(find.text('Non è una cassa'), findsOneWidget);
    await t.tap(find.text('Auto'));
    await t.pumpAndSettle();
    expect(m.answers['bb']!.isSpeaker, isTrue);
    expect(find.text('Non è una cassa'), findsNothing);
    await h.dispose(t);
  });

  testWidgets('permission row only after a refusal, and asks again', (t) async {
    final h = await Harness.create(t);
    final m = await pump(t, h, permission: false);
    expect(find.text('Permesso Bluetooth negato'), findsNothing);
    await m.declinePermission();
    await t.pumpAndSettle();
    expect(find.text('Permesso Bluetooth negato'), findsOneWidget);
    await t.tap(find.text('Permesso Bluetooth negato'));
    await t.pumpAndSettle();
    expect(m.permissionAsked, isTrue);
    await h.dispose(t);
  });
}
