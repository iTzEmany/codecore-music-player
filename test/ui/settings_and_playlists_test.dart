import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/ui/screens/playlists/playlist_detail_screen.dart';
import 'package:codecore/ui/screens/playlists/playlists_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('settings builds (with a Backup group) and theme choice is persisted in state',
      (tester) async {
    tester.view.physicalSize = const Size(500, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: SettingsScreen(initial: SettingsPage.appearance)));
    expect(find.text('Aspetto'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);
    expect(find.text('Notte viola'), findsOneWidget);
    await tester.tap(find.text('Nero puro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.store.readSettings().theme, 'oled');
    await h.dispose(tester);
  });

  testWidgets('settings has «Pulizia libreria»: duplicates open their screen, hidden tracks are counted',
      (tester) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    await tester.runAsync(() => h.db.customUpdate("UPDATE tracks SET ignored = 1 WHERE title = 'Song 0'"));
    await h.pump(tester, const Scaffold(body: SettingsScreen(initial: SettingsPage.library)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pulizia libreria'), findsOneWidget);
    expect(find.text('Brani nascosti (1)'), findsOneWidget);

    await tester.ensureVisible(find.text('Duplicati'));
    await tester.tap(find.text('Duplicati'));
    await tester.pumpAndSettle();
    expect(find.text('Cerca duplicati'), findsOneWidget);
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

  testWidgets('rename dialog is titled «Rinomina playlist»; delete asks first',
      (tester) async {
    final h = await Harness.create(tester);
    final id = (await tester.runAsync(
        () => h.db.into(h.db.playlists).insert(PlaylistsCompanion.insert(
            name: 'Rock', createdAt: 1))))!;
    final pl = Playlist(id: id, name: 'Rock', createdAt: 1, updatedAt: 1);
    await h.pump(tester, PlaylistDetailScreen(playlist: pl));
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rinomina'));
    await tester.pumpAndSettle();
    expect(find.text('Rinomina playlist'), findsOneWidget);
    expect(find.text('Nuova playlist'), findsNothing);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare la playlist?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    final left = await tester.runAsync(() => h.db.select(h.db.playlists).get());
    expect(left, hasLength(1));
    await h.dispose(tester);
  });
}
