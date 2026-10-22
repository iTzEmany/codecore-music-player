import 'package:codecore/ui/screens/search/search_screen.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// One turn of the real event loop (not real time) lets drift finish what a
/// `runAsync` write started; everything else runs on the test clock.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 400));
}

/// A title shown in a track row (the main-result card repeats the first one).
Finder _row(String title) =>
    find.descendant(of: find.byType(TrackRow), matching: find.text(title));

void main() {
  late Harness h;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 4);
    final years = [1985, 1992, 1995, 2005];
    final rows = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
    await tester.runAsync(() async {
      for (var i = 0; i < rows.length; i++) {
        await h.db.customUpdate('UPDATE tracks SET year = ${years[i]} WHERE id = ${rows[i].id}');
      }
    });
    await h.pump(tester, const SearchScreen());
    await _settle(tester);
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await _settle(tester); // the 250 ms debounce runs on the test clock
  }

  testWidgets('anno:1990..1999 shows only the tracks of those years', (tester) async {
    await open(tester);
    await type(tester, 'anno:1990..1999');
    expect(_row('Song 1'), findsOneWidget);
    expect(_row('Song 2'), findsOneWidget);
    expect(_row('Song 0'), findsNothing);
    expect(_row('Song 3'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('a negation and a plain word work together', (tester) async {
    await open(tester);
    await type(tester, 'song -"song 2"');
    expect(_row('Song 2'), findsNothing);
    expect(_row('Song 1'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('nothing in the box suggests operators; two quick filters sit under it',
      (tester) async {
    await open(tester);
    for (final op in ['artista:', 'anno:', 'genere:', 'tag:']) {
      expect(find.text(op), findsNothing);
    }
    expect(find.byTooltip('Aiuto sulla ricerca'), findsNothing);
    expect(find.widgetWithText(FilterChip, 'Preferiti'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Recenti'), findsOneWidget);
    expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Preferiti')).selected, isFalse);
    expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Recenti')).selected, isFalse);
    await h.dispose(tester);
  });

  testWidgets('«Preferiti» alone lists the favourites; with a text it limits the matches',
      (tester) async {
    await open(tester);
    await tester.runAsync(() => h.db.customUpdate('UPDATE tracks SET is_favorite = 1 WHERE title = \'Song 1\''));
    await tester.tap(find.widgetWithText(FilterChip, 'Preferiti'));
    await _settle(tester);
    expect(_row('Song 1'), findsOneWidget);
    expect(_row('Song 2'), findsNothing);
    await type(tester, 'song');
    expect(_row('Song 1'), findsOneWidget);
    expect(_row('Song 2'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'Preferiti'));
    await _settle(tester);
    expect(_row('Song 2'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('«Recenti» lists what was played or added lately', (tester) async {
    await open(tester);
    final now = DateTime.now().millisecondsSinceEpoch;
    await tester.runAsync(() => h.db.customUpdate('UPDATE tracks SET added_at = 1'));
    await tester.runAsync(
        () => h.db.customUpdate('UPDATE tracks SET last_played_at = $now WHERE title = \'Song 2\''));
    await tester.tap(find.widgetWithText(FilterChip, 'Recenti'));
    await _settle(tester);
    expect(_row('Song 2'), findsOneWidget);
    expect(_row('Song 0'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('a plain text finds by year and artist together, in any order', (tester) async {
    await open(tester);
    await type(tester, '1992 artist');
    expect(_row('Song 1'), findsOneWidget);
    expect(_row('Song 0'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('what the parser cannot read is searched as text, without a complaint',
      (tester) async {
    await open(tester);
    await type(tester, 'colore:rosso');
    expect(find.textContaining('Non capisco'), findsNothing);
    expect(find.text('Nessun risultato in libreria'), findsOneWidget);
    await h.dispose(tester);
  });
}
