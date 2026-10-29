import 'package:codecore/data/settings/jam_secret_store.dart';
import 'package:codecore/providers/jam_remote_providers.dart';
import 'package:codecore/services/jam/jam_gate.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:codecore/ui/screens/jam/jam_request_dialog.dart';
import 'package:codecore/ui/screens/settings/jam_gate_tiles.dart';
import 'package:codecore/ui/widgets/duration_choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);
  JamGate newGate() => JamGate(MemoryJamSecretStore(), now: () => now);

  Future<void> openDialog(WidgetTester t, JamGate gate) async {
    final h = await Harness.create(t);
    final req = JamRequest(
        id: 'r', fromId: 'x', fromName: 'Telefono', fromHost: '10.0.0.2',
        fromPort: 1, token: 'tttttttt', receivedAt: now);
    await h.pump(
        t,
        Builder(
            builder: (c) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(context: c, builder: (_) => JamRequestDialog(request: req)),
                    child: const Text('apri')))),
        extraOverrides: [jamGateProvider.overrideWithValue(gate)]);
    await t.tap(find.text('apri'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
  }

  testWidgets('dialog: Sospendi asks for a duration and suspends the sender', (t) async {
    final gate = newGate();
    await openDialog(t, gate);
    for (final a in ['Accetta', 'Rifiuta', 'Sospendi', 'Blocca']) {
      expect(find.text(a), findsOneWidget);
    }
    await t.tap(find.text('Sospendi'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('15 minuti'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(gate.suspended.single.id, 'x');
    expect(gate.suspended.single.when, now.add(const Duration(minutes: 15)));
    expect(find.text('Telefono vuole avviare una Jam'), findsNothing);
  });

  testWidgets('dialog: Blocca blocks the sender', (t) async {
    final gate = newGate();
    await openDialog(t, gate);
    await t.tap(find.text('Blocca'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(gate.blocked.single.name, 'Telefono');
    expect(find.text('Telefono vuole avviare una Jam'), findsNothing);
  });

  testWidgets('settings lists show blocked and suspended senders and Sblocca removes them', (t) async {
    final gate = newGate();
    await gate.ready; // loading drops the «until the Jam ends» suspensions
    gate
      ..block('a', 'Tablet')
      ..suspend('b', 'Telefono', null);
    final h = await Harness.create(t);
    await h.pump(t, const Scaffold(body: JamGateGroups()),
        extraOverrides: [jamGateProvider.overrideWithValue(gate)]);
    expect(find.text('Tablet'), findsOneWidget);
    expect(find.text('Fino alla fine della Jam'), findsOneWidget);
    await t.tap(find.text('Sblocca').first);
    await t.pump();
    expect(gate.blocked, isEmpty);
    expect(find.text('Tablet'), findsNothing);
    await t.tap(find.text('Sblocca'));
    await t.pump();
    expect(gate.suspended, isEmpty);
    expect(find.text('Telefono'), findsNothing);
  });

  testWidgets('duration sheet: cancel chip only when asked, minutes and end pop their value', (t) async {
    final h = await Harness.create(t);
    int? got;
    Future<void> open(String? cancel) async {
      await h.pump(
          t,
          Builder(
              builder: (c) => Scaffold(
                  body: TextButton(
                      onPressed: () async => got = await showDurationChoiceSheet(c,
                          title: 'T', endLabel: 'Fine', cancelLabel: cancel),
                      child: const Text('apri')))));
      await t.tap(find.text('apri'));
      await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    }

    await open(null);
    expect(find.text('Annulla'), findsNothing);
    await t.tap(find.text('45 minuti'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(got, 45);
    await open('Annulla');
    await t.tap(find.text('Annulla'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(got, 0);
    await open(null);
    await t.tap(find.text('Fine'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(got, -1);
  });
}
