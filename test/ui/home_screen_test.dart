import 'package:codecore/ui/screens/home/home_screen.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  Future<Harness> openHome(WidgetTester tester, {int tracks = 4}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: tracks);
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
    expect(find.textContaining('Preferiti'), findsOneWidget);
    expect(find.text('Aggiunti da poco'), findsOneWidget);
    expect(find.text('Riprendi'), findsNothing);
    expect(find.textContaining(' · '), findsNothing);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('the shuffle button in Home only changes the mode', (
    tester,
  ) async {
    final h = await openHome(tester);
    await tester.tap(find.text('Casuale su tutto'));
    await _settle(tester);
    expect(
      h.handler.shuffleEnabled,
      isFalse,
      reason: 'the title is not a button',
    );
    await tester.tap(find.byIcon(Icons.shuffle_rounded));
    await _settle(tester);
    expect(h.handler.shuffleEnabled, isTrue);
    expect(h.handler.queueIds, isEmpty, reason: 'nothing starts');
    await h.dispose(tester);
  });

  testWidgets(
    'the Home shuffle button reaches Shuffle+ on a library of 6 while 2 tracks play (D-137)',
    (tester) async {
      final h = await openHome(tester, tracks: 6);
      final ids = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!
          .map((t) => t.id)
          .toList();
      await tester.runAsync(() => h.handler.playQueue(ids.take(2).toList(), 0));
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byIcon(Icons.shuffle_rounded));
        await _settle(tester);
      }
      final c = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      expect(c.read(settingsProvider).shufflePlus, isTrue);
      await h.dispose(tester);
    },
  );

  testWidgets('Play starts the library in order with shuffle off', (
    tester,
  ) async {
    final h = await openHome(tester);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await _settle(tester);
    expect(h.handler.shuffleEnabled, isFalse);
    expect(h.handler.queueIds, hasLength(4));
    expect(h.handler.currentIndex, 0);
    await h.dispose(tester);
  });

  testWidgets('Play with shuffle on keeps shuffle on and starts the library', (
    tester,
  ) async {
    final h = await openHome(tester);
    await tester.tap(find.byIcon(Icons.shuffle_rounded));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.play_arrow));
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

  testWidgets('the closed fan opens from the accessibility tap action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = await openHome(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('fan-cover-0')));
    await tester.pump();
    tester.semantics.performAction(
      find.semantics.byLabel(RegExp('Mostra le copertine')),
      SemanticsAction.tap,
    );
    await _settle(tester);
    expect(find.bySemanticsLabel(RegExp('Mostra le copertine')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('fan-cover-0')));
    await _settle(tester);
    expect(find.byType(AlbumDetailScreen), findsOneWidget);
    await h.dispose(tester);
    handle.dispose();
  });

  testWidgets(
    'Riprendi shows a track left in the middle with the minutes left',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester, tracks: 4);
      await tester.runAsync(
        () => (h.db.update(h.db.tracks)..where((t) => t.title.equals('Song 2')))
            .write(
              const TracksCompanion(
                resumePositionMs: Value(60000),
                lastPlayedAt: Value(1000),
              ),
            ),
      );
      await h.pump(tester, const HomeScreen());
      await _settle(tester);
      expect(find.text('Riprendi'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
      // 185 s long, 60 s in: 125 s left rounds up to 3 minutes.
      expect(find.text('Mancano 3 minuti'), findsOneWidget);
      await h.dispose(tester);
    },
  );

  testWidgets('Riprendi shows the playing queue as «brano n di m»', (
    tester,
  ) async {
    final h = await openHome(tester);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await _settle(tester);
    final row = find.byKey(const ValueKey('resume-queue'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining(RegExp(r'rano \d di 4')),
      ),
      findsOneWidget,
    );
    await h.dispose(tester);
  });

  testWidgets('wide window: Home uses the width, fan shows covers or art', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const HomeScreen());
    await _settle(tester);
    expect(
      tester.getSize(find.byType(ListView).first).width,
      greaterThan(1000),
    );
    final cover = find.byKey(const ValueKey('fan-cover-0'));
    expect(cover, findsOneWidget);
    expect(
      find.descendant(of: cover, matching: find.byType(Text)),
      findsOneWidget,
    );
    expect(tester.getSize(cover).width, 84);
    await h.dispose(tester);
  });
}
