import 'package:codecore/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/ui/screens/jam/jam_request_dialog.dart';
import 'package:codecore/ui/screens/jam/jam_screen.dart';
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

JamUiState active({required bool host}) => JamUiState(
      phase: JamPhase.active,
      role: host ? JamRole.host : JamRole.guest,
      peerName: 'Telefono',
      peerId: 'peer',
      jam: const JamState(
        version: 3,
        items: [
          JamItem(id: 1, ownerDeviceId: 'host', title: 'Prima', ext: 'mp3',
              artist: 'Band', durationMs: 180000),
          JamItem(id: 2, ownerDeviceId: 'peer', title: 'Seconda', ext: 'mp3',
              durationMs: 200000),
        ],
        currentIndex: 0,
        playing: true,
        hostDeviceId: 'host',
        outputDeviceId: 'host',
      ),
    );

void main() {
  for (final host in [true, false]) {
    testWidgets('jam screen as ${host ? 'host' : 'guest'}', (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final h = await Harness.create(tester);
      final fake = _FakeJam(active(host: host));
      await tester.pumpWidget(ProviderScope(
        overrides: [...h.overrides, jamProvider.overrideWith(() => fake)],
        child: MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const JamScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Jam'), findsWidgets);
      expect(find.text('Prima'), findsWidgets);
      expect(find.text('Seconda'), findsOneWidget);
      expect(find.text('Aggiungi brani'), findsOneWidget);
      expect(find.byTooltip('Brano successivo'),
          host ? findsOneWidget : findsNothing);
      expect(find.text(host ? 'Termina Jam' : 'Esci dalla Jam'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await h.dispose(tester);
    });
  }

  testWidgets('jam request dialog', (tester) async {
    final h = await Harness.create(tester);
    final req = JamRequest(
        id: 'r', fromId: 'x', fromName: 'Telefono', fromHost: '10.0.0.2',
        fromPort: 1, token: 'tttttttt', receivedAt: DateTime.now());
    await h.pump(tester, JamRequestDialog(request: req));
    expect(find.text('Telefono vuole avviare una Jam'), findsOneWidget);
    expect(find.text('Accetta'), findsOneWidget);
    expect(find.text('Rifiuta'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('request dialog closes by itself when the requester cancels',
      (tester) async {
    final h = await Harness.create(tester);
    final req = JamRequest(
        id: 'r', fromId: 'x', fromName: 'Telefono', fromHost: '10.0.0.2',
        fromPort: 1, token: 'tttttttt', receivedAt: DateTime.now());
    await h.pump(
        tester,
        Builder(
            builder: (c) => Scaffold(
                body: Center(
                    child: TextButton(
                        onPressed: () => showDialog<void>(
                            context: c,
                            builder: (_) => JamRequestDialog(request: req)),
                        child: const Text('apri'))))));
    await tester.tap(find.text('apri'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Telefono vuole avviare una Jam'), findsOneWidget);
    req.status = JamRequestStatus.cancelled;
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Telefono vuole avviare una Jam'), findsNothing);
    // the page underneath is still there
    expect(find.text('apri'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('synchronised outputs show the offset and the latency control',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final base = active(host: true);
    final synced = JamUiState(
      phase: base.phase,
      role: base.role,
      peerName: base.peerName,
      peerId: base.peerId,
      syncErrorMs: -12,
      jam: base.jam!.copyWith(
        outputDeviceId: 'host',
        outputDeviceIds: const ['host', 'peer'],
        participants: const [
          JamParticipant(id: 'host', name: 'PC'),
          JamParticipant(id: 'peer', name: 'Telefono', host: '10.0.0.3', port: 1),
        ],
      ),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...h.overrides,
        jamProvider.overrideWith(() => _FakeJam(synced)),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const JamScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Uscite e sincronia'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sincronizzato · scarto 12 ms'), findsOneWidget);
    expect(find.textContaining('Latenza di questa uscita'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await h.dispose(tester);
  });
}
