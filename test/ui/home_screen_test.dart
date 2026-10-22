import 'package:codecore/ui/screens/home/home_screen.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('home without music: empty state with add folder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const HomeScreen());
    await _settle(tester);
    expect(find.text('Aggiungi la tua cartella musicale'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    await h.dispose(tester);
  });

  Future<Harness> openHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const HomeScreen());
    await _settle(tester);
    return h;
  }

  testWidgets('home with music: shuffle hero, shortcuts, fan, no Riprendi', (
    tester,
  ) async {
    final h = await openHome(tester);
    expect(find.text('Casuale su tutto'), findsOneWidget);
    expect(find.textContaining('4 brani'), findsOneWidget);
    expect(find.text('Preferiti'), findsOneWidget);
    expect(find.text('Aggiunti da poco'), findsOneWidget);
    expect(find.text('Riprendi'), findsNothing);
    expect(find.textContaining(' · '), findsNothing);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('Casuale su tutto turns shuffle on and starts playing', (
    tester,
  ) async {
    final h = await openHome(tester);
    await tester.tap(find.text('Casuale su tutto'));
    await _settle(tester);
    expect(h.handler.shuffleEnabled, isTrue);
    expect(h.handler.queueIds, hasLength(4));
    await h.dispose(tester);
  });

  testWidgets(
    'the fan opens on the first tap and opens the album on the second',
    (tester) async {
      final h = await openHome(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('fan-cover-0')));
      await tester.tap(
        find.byKey(const ValueKey('fan-cover-1')),
        warnIfMissed: false,
      );
      await _settle(tester);
      expect(find.byType(AlbumDetailScreen), findsNothing);
      await tester.tap(find.byKey(const ValueKey('fan-cover-0')));
      await _settle(tester);
      expect(find.byType(AlbumDetailScreen), findsOneWidget);
      await h.dispose(tester);
    },
  );
}
