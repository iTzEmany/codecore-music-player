import 'package:codecore/ui/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('library: pinned items, kind chips, grid toggle',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    // Pinned first, then albums and artists mixed.
    expect(find.text('Preferiti'), findsWidgets);
    expect(find.text('Tutti i brani'), findsOneWidget);
    expect(find.text('4 brani'), findsOneWidget);
    expect(find.text('Album 0'), findsOneWidget);
    expect(find.text('Artista'), findsOneWidget);
    // «Artisti» chip keeps only the artists.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Artisti'));
    await _settle(tester);
    expect(find.text('Album 0'), findsNothing);
    expect(find.text('Artista'), findsOneWidget);
    // Tapping it again shows everything; the grid toggle keeps the content.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Artisti'));
    await _settle(tester);
    expect(find.text('Album 0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await _settle(tester);
    expect(find.text('Album 0'), findsOneWidget);
    expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });
}
