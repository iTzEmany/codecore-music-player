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

  testWidgets('the suggestion chips put an operator in the box', (tester) async {
    await open(tester);
    final chips = find
        .byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal)
        .first;
    expect(find.text('artista:'), findsOneWidget);
    expect(find.text('anno:'), findsOneWidget);
    expect(find.text('genere:'), findsOneWidget);
    await tester.drag(chips, const Offset(-600, 0)); // the row scrolls
    await tester.pump();
    expect(find.text('tag:'), findsOneWidget);
    expect(find.text('preferiti'), findsOneWidget);
    await tester.drag(chips, const Offset(600, 0));
    await tester.pump();
    await tester.tap(find.text('anno:'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'anno:');
    await type(tester, 'anno:1992');
    await tester.drag(chips, const Offset(-600, 0));
    await tester.pump();
    await tester.tap(find.text('preferiti'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'anno:1992 preferiti');
    await h.dispose(tester);
  });

  testWidgets('what the parser cannot read is said, and searched as text', (tester) async {
    await open(tester);
    await type(tester, 'colore:rosso');
    expect(find.textContaining('Non capisco «colore:rosso»'), findsOneWidget);
    await type(tester, 'anno:');
    expect(find.textContaining('Non capisco'), findsNothing, reason: 'still typing: no complaint');
    await h.dispose(tester);
  });

  testWidgets('the «?» opens the guide to the operators', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Aiuto sulla ricerca'));
    await _settle(tester);
    expect(find.text('Cercare con gli operatori'), findsOneWidget);
    expect(find.textContaining('anno:1990..1999'), findsOneWidget);
    expect(find.textContaining('rock OR jazz'), findsOneWidget);
    await h.dispose(tester);
  });
}

