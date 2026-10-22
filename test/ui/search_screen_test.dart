import 'package:codecore/core/constants.dart';
import 'package:codecore/ui/screens/search/search_screen.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/search_input.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('search: typing shows library sections, never starts YouTube',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const SearchScreen());
    await _settle(tester);
    // Empty query: no results yet; the Online chip follows the flag.
    expect(find.text('Risultato principale'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Online'),
        kEnableYoutube ? findsOneWidget : findsNothing);
    typeSearch(tester, 'Song 1');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text('Risultato principale'), findsOneWidget);
    expect(find.text('Brani'), findsOneWidget);
    // Plain words still search as text (no operator involved).
    Finder row(String title) =>
        find.descendant(of: find.byType(TrackRow), matching: find.text(title));
    expect(row('Song 1'), findsOneWidget);
    expect(row('Song 0'), findsNothing);
    // Typing did not switch to YouTube mode.
    expect(find.text('Cerca un brano o incolla un link'), findsNothing);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('search without matches says so', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const SearchScreen());
    typeSearch(tester, 'zzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text('Nessun risultato in libreria'), findsOneWidget);
    await h.dispose(tester);
  });
}
