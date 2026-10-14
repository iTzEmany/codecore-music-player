import 'package:codecore/ui/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('narrow: bottom bar, empty state with add folder', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Aggiungi la tua cartella musicale'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('wide: navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    expect(find.byType(NavigationRail), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('tracks listed; tap plays and shows mini player', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell());
    expect(find.text('Song 0'), findsOneWidget);
    expect(find.text('3 brani'), findsOneWidget);
    await tester.tap(find.text('Song 1'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.handler.currentTrack?.title, 'Song 1');
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
    await h.dispose(tester);
  });
}
