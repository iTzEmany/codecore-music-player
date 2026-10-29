import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/ui/screens/jam/jam_queue_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _FakeJam extends JamController {
  _FakeJam(this.initial);
  final JamUiState initial;
  final sent = <JamCommand>[];

  @override
  JamUiState build() => initial;

  @override
  Future<JamError?> send(JamCommand cmd) async {
    sent.add(cmd);
    return null;
  }
}

JamUiState _state({required bool host, JamMode mode = JamMode.host}) => JamUiState(
      phase: JamPhase.active,
      role: host ? JamRole.host : JamRole.guest,
      peerName: 'Telefono',
      peerId: 'peer',
      jam: JamState(
        version: 3,
        mode: mode,
        items: const [
          JamItem(id: 1, ownerDeviceId: 'host', title: 'Prima', ext: 'mp3', durationMs: 1000),
          JamItem(id: 2, ownerDeviceId: 'peer', title: 'Seconda', ext: 'mp3',
              durationMs: 1000, suggested: true),
        ],
        currentIndex: 0,
        hostDeviceId: 'host',
        outputDeviceId: 'host',
      ),
    );

Future<(_FakeJam, Harness)> _open(WidgetTester tester, JamUiState s) async {
  final h = await Harness.create(tester);
  final fake = _FakeJam(s);
  await h.pump(
    tester,
    Scaffold(
      body: CustomScrollView(slivers: const [JamQueueSliver()]),
    ),
    extraOverrides: [jamProvider.overrideWith(() => fake)],
  );
  return (fake, h);
}

void main() {
  testWidgets('host: la riga della modalità cambia la coda', (tester) async {
    final (fake, h) = await _open(tester, _state(host: true));
    expect(find.text("Coda dell'host"), findsOneWidget);
    await tester.tap(find.text('Coda insieme'));
    await tester.pump();
    expect(fake.sent.single.type, JamCommandType.setMode);
    expect(fake.sent.single.mode, JamMode.together);
    await h.dispose(tester);
  });

  testWidgets('ospite: la riga c\'è ma non si tocca', (tester) async {
    final (fake, h) = await _open(tester, _state(host: false));
    expect(find.text('Coda insieme'), findsOneWidget);
    await tester.tap(find.text('Coda insieme'), warnIfMissed: false);
    await tester.pump();
    expect(fake.sent, isEmpty);
    await h.dispose(tester);
  });

  testWidgets('in «Coda insieme» niente maniglie; «Suggerito» sull\'item suggerito', (tester) async {
    final (_, h) = await _open(tester, _state(host: true, mode: JamMode.together));
    expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
    expect(find.textContaining('Suggerito'), findsOneWidget);
    await h.dispose(tester);
    final (_, h2) = await _open(tester, _state(host: true));
    expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));
    await h2.dispose(tester);
  });
}
