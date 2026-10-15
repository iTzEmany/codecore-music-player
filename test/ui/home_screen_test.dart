import 'package:codecore/ui/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('home without music: empty state with add folder',
      (tester) async {
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

  testWidgets('home with music: Favourites tile and the recently added shelf',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const HomeScreen());
    await _settle(tester);
    expect(find.text('Preferiti'), findsOneWidget);
    expect(find.text('Aggiunti di recente'), findsOneWidget);
    // Nothing was played: no «recently played» or «most played» shelf.
    expect(find.text('Ascoltati di recente'), findsNothing);
    expect(find.text('I più ascoltati'), findsNothing);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });
}
