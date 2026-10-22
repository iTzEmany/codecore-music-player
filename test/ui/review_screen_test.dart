import 'package:codecore/ui/screens/library/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('review chips wrap and picking clears the selection', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 3);
    await tester.runAsync(
      () => h.db.customUpdate("UPDATE tracks SET enrich_status = 2 WHERE title = 'Song 0'"),
    );
    await h.pump(tester, const ReviewScreen(), textScale: 1.5);
    await _settle(tester);
    expect(
      find.ancestor(of: find.byType(ChoiceChip).first, matching: find.byType(Wrap)),
      findsOneWidget,
    );
    final rows = {
      for (final e in find.byType(ChoiceChip).evaluate())
        tester.getTopLeft(find.byWidget(e.widget)).dy,
    };
    expect(rows.length, greaterThan(1));
    await tester.longPress(find.text('Song 0'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('review-dismiss')), findsOneWidget);
    await tester.tap(find.byType(ChoiceChip).at(1));
    await _settle(tester);
    expect(find.byKey(const ValueKey('review-dismiss')), findsNothing);
    await h.dispose(tester);
  });

  testWidgets(
    'filters narrow the list and «Va bene così» removes the picked row',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester, tracks: 3);
      await tester.runAsync(() async {
        // Song 0: nothing found; Song 1: found but no lyrics; Song 2: not tried.
        await h.db.customUpdate(
          "UPDATE tracks SET enrich_status = 2 WHERE title = 'Song 0'",
        );
        await h.db.customUpdate(
          "UPDATE tracks SET enrich_status = 1, lyrics_plain = 'x', has_cover = 1, year = 2000, genre = 'Rock' WHERE title = 'Song 1'",
        );
        await h.db.customUpdate(
          "UPDATE tracks SET lyrics_plain = NULL WHERE title = 'Song 1'",
        );
      });
      await h.pump(tester, const ReviewScreen());
      await _settle(tester);
      expect(find.text('Song 0'), findsOneWidget);
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsNothing);
      // The reasons sit on their own line, not appended to the subtitle.
      final reasons = tester.widget<Text>(
        find.byWidgetPredicate((w) => w.key.toString().contains('review-reasons-')).first,
      );
      expect(reasons.data, contains('Nessun risultato'));
      expect(reasons.maxLines, 2);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Senza testo'));
      await _settle(tester);
      expect(find.text('Song 0'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Nessun risultato'));
      await _settle(tester);
      expect(find.text('Song 0'), findsOneWidget);
      expect(find.text('Song 1'), findsNothing);

      await tester.longPress(find.text('Song 0'));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('review-dismiss')));
      await _settle(tester);
      expect(find.text('Song 0'), findsNothing);
      expect(
        find.text('Niente da revisionare: ai brani cercati non manca nulla'),
        findsOneWidget,
      );
      await h.dispose(tester);
    },
  );
}
