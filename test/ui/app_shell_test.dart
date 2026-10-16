import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/shell/desktop_player_bar.dart';
import 'package:codecore/ui/shell/desktop_sidebar.dart';
import 'package:codecore/ui/shell/side_panel.dart';
import 'package:codecore/ui/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('narrow: three labelled tabs, home first', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Cerca'), findsWidgets);
    expect(find.text('Libreria'), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('library tab: empty state with add folder', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aggiungi la tua cartella musicale'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('wide: sidebar and player bar, no rail, no mini-player',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
    await h.pump(tester, const AppShell());
    await _settle(tester);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.byType(DesktopPlayerBar), findsOneWidget);
    expect(find.text('La tua libreria'), findsOneWidget);
    expect(find.text('Preferiti'), findsWidgets);
    // From 1200 px the queue opens by itself in the right-hand panel; its
    // button closes it and opens it again.
    expect(find.byType(SidePanelView), findsOneWidget);
    await tester.tap(find.byIcon(Icons.queue_music_rounded).last);
    await _settle(tester);
    expect(find.byType(SidePanelView), findsNothing);
    await tester.tap(find.byIcon(Icons.queue_music_rounded).last);
    await _settle(tester);
    expect(find.byType(SidePanelView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('tracks listed in Library; tap plays and shows mini player',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    expect(find.text('Song 0'), findsWidgets);
    await tester.tap(find.text('Song 1').first);
    await _settle(tester);
    expect(h.handler.currentTrack?.title, 'Song 1');
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byIcon(Icons.devices_rounded), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('opening an album keeps mini-player and bar; back closes it',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    await tester.tap(find.text('Song 0').first);
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await _settle(tester);
    // Library lists the albums directly: open the first one.
    await tester.tap(find.text('Album 0').first);
    await _settle(tester);
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.text('Libreria'), findsWidgets); // bottom bar still there
    // Android back: the album page goes first, back on the Library.
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('Album 1'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('mini-player: favourite, devices sheet, no nearby devices',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    await tester.tap(find.text('Song 0').first);
    await _settle(tester);
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
    await tester.tap(find.byIcon(Icons.devices_rounded));
    await _settle(tester);
    expect(find.text('Dispositivi'), findsWidgets);
    expect(find.text('Rendi visibile questo dispositivo'), findsOneWidget);
    expect(find.text('Collegamento manuale (IP e PIN)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('Ctrl+F goes to the Search tab', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });
}
