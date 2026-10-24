// Characterization (38.5): the «add folder» flow is written twice (F-07) and
// the copies diverge. Today adding a folder in the onboarding does not scan;
// the scan starts when the guide ends. D-12 changes that on purpose: whoever
// does it updates these tests in the same step.
//
// «Aggiungi cartella» itself opens the system picker (a static call), so it is
// not driven here; folders are put in the database the way the picker would.
import 'package:codecore/data/repositories/folder_repository.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/ui/screens/library/folders_sheet.dart';
import 'package:codecore/ui/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const _gone = '/nonexistent/codecore-folders-test';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

ScanState _scan(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
    .read(scanStateProvider);

Future<void> _addFolder(WidgetTester tester, Harness h) async {
  // In a transaction: see onboarding_test.dart.
  await tester.runAsync(() => h.db.transaction(() => FolderRepository(h.db).add(_gone)));
  await _settle(tester);
}

void main() {
  group('onboarding', () {
    testWidgets('a folder added on the folders page is not scanned', (tester) async {
      final h = await Harness.create(tester);
      await h.pump(tester, const OnboardingScreen(askAudioPermission: false));
      await tester.tap(find.text('Avanti'));
      await _settle(tester);
      await _addFolder(tester, h);
      expect(find.text('1 cartella aggiunta'), findsOneWidget);
      final s = _scan(tester);
      expect(s.running, isFalse);
      expect(s.progress, isNull, reason: 'no scan ran');
      expect(s.error, isNull);
      await h.dispose(tester);
    });

    testWidgets('the scan starts only when the guide ends (here «Salta»), and only with folders', (tester) async {
      final h = await Harness.create(tester);
      await h.pump(tester, const OnboardingScreen(askAudioPermission: false));
      await tester.tap(find.text('Avanti'));
      await _settle(tester);
      await _addFolder(tester, h);
      await tester.tap(find.text('Salta'));
      await _settle(tester);
      expect(_scan(tester).error, contains(_gone), reason: 'the unreachable folder was visited');
      await h.dispose(tester);
    });

    testWidgets('«Salta» without folders does not scan', (tester) async {
      final h = await Harness.create(tester);
      await h.pump(tester, const OnboardingScreen(askAudioPermission: false));
      await tester.tap(find.text('Salta'));
      await _settle(tester);
      expect(_scan(tester).progress, isNull);
      await h.dispose(tester);
    });
  });

  group('folders sheet', () {
    Future<Harness> open(WidgetTester tester) async {
      final h = await Harness.create(tester);
      await tester.runAsync(() => h.db.transaction(() => FolderRepository(h.db).add(_gone)));
      await h.pump(tester, const Scaffold(body: FoldersSheet()));
      await _settle(tester);
      return h;
    }

    testWidgets('lists the folders by path', (tester) async {
      final h = await open(tester);
      expect(find.text(_gone), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('the refresh button scans straight away', (tester) async {
      final h = await open(tester);
      await tester.tap(find.byTooltip('Aggiorna libreria'));
      await _settle(tester);
      expect(_scan(tester).error, contains(_gone));
      await h.dispose(tester);
    });

    testWidgets('removing a folder asks first: cancel keeps it, confirm drops it', (tester) async {
      final h = await open(tester);
      await tester.tap(find.byTooltip('Rimuovi cartella'));
      await _settle(tester);
      await tester.tap(find.text('Annulla'));
      await _settle(tester);
      expect(find.text(_gone), findsOneWidget);
      await tester.tap(find.byTooltip('Rimuovi cartella'));
      await _settle(tester);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await _settle(tester);
      expect(find.text(_gone), findsNothing);
      await h.dispose(tester);
    });
  });
}
