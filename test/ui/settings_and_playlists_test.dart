import 'package:codecore/ui/screens/playlists/playlists_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('settings builds and theme choice is persisted in state',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: SettingsScreen()));
    expect(find.text('Aspetto'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);
    expect(find.text('Arricchimento automatico'), findsOneWidget);
    await tester.tap(find.text('Chiaro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.store.readSettings().theme, 'light');
    await h.dispose(tester);
  });

  testWidgets('playlists empty state and creation', (tester) async {
    final h = await Harness.create(tester);
    await h.pump(tester, const PlaylistsScreen());
    expect(find.text('Nessuna playlist. Creane una.'), findsOneWidget);
    await tester.tap(find.text('Nuova playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Rock');
    await tester.tap(find.text('Crea'));
    await tester.pumpAndSettle();
    expect(find.text('Rock'), findsOneWidget);
    await h.dispose(tester);
  });
}
