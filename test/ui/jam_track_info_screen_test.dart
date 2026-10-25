import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/share/track_meta.dart';
import 'package:codecore/ui/screens/jam/jam_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      jam: const JamState(
        version: 3,
        items: [
          JamItem(id: 1, ownerDeviceId: 'host', title: 'Prima', ext: 'mp3'),
          JamItem(id: 2, ownerDeviceId: 'peer', title: 'Seconda', ext: 'mp3', artist: 'Band'),
        ],
        currentIndex: 0,
        hostDeviceId: 'host',
        outputDeviceId: 'host',
      ),
    );

void main() {
  for (final host in [true, false]) {
    testWidgets('tap on a row opens the info screen as ${host ? 'host' : 'guest'}', (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester);
      final fake = _FakeJam(active(host: host));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...h.overrides,
          jamProvider.overrideWith(() => fake),
          jamTrackCoverProvider.overrideWith((ref, id) async => null),
        jamTrackMetaProvider.overrideWith((ref, id) async =>
              id == 2 ? const TrackMeta(title: 'Seconda', lyricsPlain: 'parole', curiosities: 'Una storia\nhttps://it.wikipedia.org/wiki/X') : const TrackMeta()),
        ],
        child: MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const JamScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      // «Salta qui» is in the row menu for the host only
      // «Vai all'artista» is in the menu of a row with an artist; «Salta qui» only for the host.
      expect(find.byTooltip('Altre azioni'), host ? findsNWidgets(2) : findsOneWidget);

      await tester.tap(find.text('Seconda'));
      await tester.pumpAndSettle();
      expect(find.text('Info sul brano'), findsOneWidget);
      expect(find.text('parole'), findsOneWidget);
      expect(find.text('Una storia'), findsOneWidget);
      expect(find.text('Curiosità'), findsOneWidget);
      expect(find.text('Salta qui'), host ? findsOneWidget : findsNothing);
      expect(find.text('Vai all’artista'), findsOneWidget);
      if (host) {
        await tester.tap(find.text('Salta qui'));
        await tester.pumpAndSettle();
        expect(fake.sent.single.type, JamCommandType.jump);
        expect(fake.sent.single.itemId, 2);
      }
      await tester.pumpWidget(const SizedBox());
      await h.dispose(tester);
    });
  }

  testWidgets('without meta the screen shows the item\'s basic data', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...h.overrides,
        jamProvider.overrideWith(() => _FakeJam(active(host: false))),
        jamTrackCoverProvider.overrideWith((ref, id) async => null),
        jamTrackMetaProvider.overrideWith((ref, id) async =>
            const TrackMeta(title: 'Seconda', artist: 'Band')),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const JamScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Seconda'));
    await tester.pumpAndSettle();
    expect(find.text('Band'), findsWidgets);
    expect(find.text('Testo'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await h.dispose(tester);
  });
}
