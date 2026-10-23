import 'package:codecore/data/repositories/folder_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/ui/screens/onboarding/onboarding_gate.dart';
import 'package:codecore/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

AppSettings _settings(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(Scaffold).first.evaluate().isEmpty ? find.byType(MaterialApp) : find.byType(Scaffold).first),
).read(settingsProvider);

Future<void> _openGate(WidgetTester tester, Harness h) async {
  await h.pump(tester, const OnboardingGate(child: Scaffold(body: Text('APP'))));
  await _settle(tester);
}

void main() {
  testWidgets('a first start with an empty library opens the guide, not the app', (tester) async {
    final h = await Harness.create(tester);
    await _openGate(tester, h);
    expect(find.text('Benvenuto in Codecore'), findsOneWidget);
    expect(find.text('APP'), findsNothing);
    expect(find.text('Salta'), findsOneWidget);
    expect(find.text('Avanti'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('«Salta» goes to the app and the guide is not shown again', (tester) async {
    final h = await Harness.create(tester);
    await _openGate(tester, h);
    await tester.tap(find.text('Salta'));
    await _settle(tester);
    expect(find.text('APP'), findsOneWidget);
    expect(_settings(tester).onboardingDone, isTrue);
    expect(_settings(tester).ytNoticeSeen, isFalse, reason: 'skipped before the notice');
    expect(h.store.readSettings().onboardingDone, isTrue, reason: 'saved');
    await h.dispose(tester);
  });

  testWidgets('five pages with Avanti, the last says «Inizia» and marks the notice as seen', (tester) async {
    final h = await Harness.create(tester);
    await _openGate(tester, h);
    for (final title in ['La tua musica', 'Funzioni online', 'Playlist da Spotify', 'Download, Jam e condivisione']) {
      await tester.tap(find.text('Avanti'));
      await _settle(tester);
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Avanti'), findsNothing);
    expect(find.textContaining('diritti d’autore'), findsOneWidget, reason: 'the notice');
    await tester.tap(find.text('Inizia'));
    await _settle(tester);
    expect(find.text('APP'), findsOneWidget);
    expect(_settings(tester).onboardingDone, isTrue);
    expect(_settings(tester).ytNoticeSeen, isTrue);
    await h.dispose(tester);
  });

  testWidgets('the online features start off and can be turned on', (tester) async {
    final h = await Harness.create(tester);
    await _openGate(tester, h);
    await tester.tap(find.text('Avanti'));
    await _settle(tester);
    await tester.tap(find.text('Avanti'));
    await _settle(tester);
    expect(_settings(tester).autoEnrich, isFalse);
    expect(_settings(tester).autoLyrics, isFalse);
    await tester.tap(find.text('Arricchimento automatico'));
    await _settle(tester);
    expect(_settings(tester).autoEnrich, isTrue);
    expect(_settings(tester).autoLyrics, isFalse);
    await h.dispose(tester);
  });

  testWidgets('the Spotify page leaves the reminder off, and a choice is saved', (tester) async {
    final h = await Harness.create(tester);
    await _openGate(tester, h);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Avanti'));
      await _settle(tester);
    }
    expect(find.text('Playlist da Spotify'), findsOneWidget);
    expect(h.store.readExportifyRemindDays(), 0);
    await tester.ensureVisible(find.text('14 giorni'));
    await tester.pump();
    await tester.tap(find.text('14 giorni'));
    await _settle(tester);
    expect(h.store.readExportifyRemindDays(), 14);
    await h.dispose(tester);
  });

  testWidgets('adding a folder on the way does not close the guide', (tester) async {
    final h = await Harness.create(tester);
    await _openGate(tester, h);
    await tester.tap(find.text('Avanti'));
    await _settle(tester);
    // In a transaction: a plain statement after a stream update waits for
    // timers the test clock holds back (drift + FakeAsync).
    await tester.runAsync(
      () => h.db.transaction(() => FolderRepository(h.db).add('/tmp/codecore-onboarding')),
    );
    await _settle(tester);
    expect(find.text('La tua musica'), findsOneWidget);
    expect(find.text('1 cartella aggiunta'), findsOneWidget);
    expect(find.text('APP'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('someone who already has music never sees it, and is not asked later', (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    await _openGate(tester, h);
    expect(find.text('APP'), findsOneWidget);
    expect(find.text('Benvenuto in Codecore'), findsNothing);
    await _settle(tester);
    expect(_settings(tester).onboardingDone, isTrue);
    await h.dispose(tester);
  });

  testWidgets('once done it never comes back, even with an empty library', (tester) async {
    final h = await Harness.create(tester);
    await h.store.writeSettings(const AppSettings(onboardingDone: true));
    await h.pump(tester, const OnboardingGate(child: Scaffold(body: Text('APP'))));
    await _settle(tester);
    expect(find.text('APP'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('on Android the audio permission is explained first, then asked', (tester) async {
    final h = await Harness.create(tester);
    await h.pump(tester, const OnboardingScreen(askAudioPermission: true));
    await tester.tap(find.text('Avanti'));
    await _settle(tester);
    expect(find.textContaining('permesso di leggere i file audio'), findsOneWidget);
    await tester.tap(find.text('Consenti l’accesso ai file audio'));
    await _settle(tester);
    expect(find.text('Accesso consentito'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('without the Android permission step the folders page has no such button', (tester) async {
    final h = await Harness.create(tester);
    await h.pump(tester, const OnboardingScreen(askAudioPermission: false));
    await tester.tap(find.text('Avanti'));
    await _settle(tester);
    expect(find.text('Consenti l’accesso ai file audio'), findsNothing);
    await h.dispose(tester);
  });
}
