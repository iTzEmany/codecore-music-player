import 'package:codecore/providers/memory_providers.dart';
import 'package:codecore/providers/nav_providers.dart';
import 'package:codecore/services/memory/app_data.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/ui/screens/library/all_tracks_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/shell/bottom_bar.dart';
import 'package:codecore/ui/shell/desktop_player_bar.dart';
import 'package:codecore/ui/shell/desktop_sidebar.dart';
import 'package:codecore/ui/shell/side_panel.dart';
import 'package:codecore/ui/widgets/mini_player.dart';
import 'package:codecore/ui/widgets/motion.dart';
import 'package:codecore/ui/widgets/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

Finder _bar(String label) => find.descendant(
    of: find.byType(ShellDock), matching: find.text(label));

void main() {
  testWidgets('no track: dock holds only the tabs', (t) async {
    _phone(t);
    final h = await Harness.create(t, tracks: 2);
    await h.pump(t, const AppShell());
    await _settle(t);
    expect(find.byType(ShellDock), findsOneWidget);
    expect(find.byType(MiniPlayer), findsNothing);
    expect(_bar('Home'), findsOneWidget);
    await h.dispose(t);
  });

  testWidgets('the selected tab is marked by the dot and in semantics',
      (t) async {
    _phone(t);
    final h = await Harness.create(t, tracks: 2);
    await h.pump(t, const AppShell());
    await t.tap(_bar('Libreria'));
    await _settle(t);
    await t.pump(Motion.dot); // the hop is still on its way after _settle
    final tab = find.ancestor(of: _bar('Libreria'), matching: find.byType(InkWell));
    expect(t.getSemantics(tab.first), isSemantics(isSelected: true, isButton: true));
    final corner = t.getTopRight(
        find.descendant(of: tab, matching: find.byType(Icon)));
    final dot = t.getCenter(find.byKey(const ValueKey('tab-dot')));
    expect((dot - corner).distance, lessThan(16));
    await h.dispose(t);
  });

  testWidgets('narrow: four labelled tabs, home first', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Cerca'), findsWidgets);
    expect(find.text('Libreria'), findsWidgets);
    expect(find.text('Memoria'), findsWidgets);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    await h.dispose(tester);
  });

  final memoryOverrides = [
    appDataUsageProvider.overrideWith(
      (_) async => [const AppDataItem(AppDataKind.covers, 2048, detailBytes: 512)],
    ),
    musicDiskSpaceProvider.overrideWith((_) async => null),
  ];

  testWidgets('Memoria tab opens the storage page', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell(), extraOverrides: memoryOverrides);
    // Nothing is measured until the tab is shown.
    expect(find.text('Riepilogo'), findsNothing);
    await tester.tap(find.text('Memoria'));
    await _settle(tester);
    expect(find.text('Riepilogo'), findsOneWidget);
    expect(find.text('3 B'), findsWidgets);
    expect(find.text('MP3'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Copertine'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Copertine'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('sidebar has a Memoria entry that opens the same page', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell(), extraOverrides: memoryOverrides);
    await tester.tap(find.descendant(
        of: find.byType(DesktopSidebar), matching: find.text('Memoria')));
    await _settle(tester);
    expect(find.text('Riepilogo'), findsOneWidget);
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
    await _settle(tester);
    expect(find.byType(AlbumDetailScreen), findsNothing);
    expect(find.text('Album 0'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets(
      'tracks listed in Library; tap plays and shows the mini-player: '
      'favourite, devices sheet, no nearby devices', (tester) async {
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
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
    expect(find.byIcon(Icons.devices_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.devices_rounded));
    await _settle(tester);
    expect(find.text('Dispositivi'), findsWidgets);
    expect(find.text('Rendi visibile questo dispositivo'), findsOneWidget);
    expect(find.text('Collegamento manuale (IP e PIN)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('system back in selection mode ends the selection and keeps the page',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    await tester.longPress(find.text('Song 0').first);
    await _settle(tester);
    expect(find.byType(SelectionBar), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(SelectionBar), findsNothing);
    expect(find.byType(AllTracksScreen), findsOneWidget); // still on the page
    // A second back leaves the page.
    await tester.binding.handlePopRoute();
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(AllTracksScreen), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('the mini-player label is title and artist, with no progress value', (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    await tester.tap(find.text('Song 1').first);
    await _settle(tester);
    h.backend.posC.add(const Duration(seconds: 30));
    h.backend.durC.add(const Duration(seconds: 60));
    await _settle(tester);
    final node = tester.getSemantics(
        find.descendant(of: find.byType(MiniPlayer), matching: find.text('Song 1')));
    expect(node.label, startsWith('Song 1'));
    expect(node.value, isEmpty, reason: 'the progress bar value would lead the spoken label');
    handle.dispose();
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
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    expect(container.read(navIndexProvider), NavTab.search.index);
    await h.dispose(tester);
  });

  testWidgets('sidebar «La tua libreria» closes a page left open in that tab',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('La tua libreria'));
    await _settle(tester);
    await tester.tap(find.descendant(
        of: find.byType(DesktopSidebar), matching: find.text('Preferiti')));
    await _settle(tester);
    expect(find.text('Nessun preferito ancora'), findsOneWidget);
    await tester.tap(find.text('Home').first);
    await _settle(tester);
    await tester.tap(find.text('La tua libreria'));
    await _settle(tester);
    await _settle(tester);
    await _settle(tester);
    expect(find.text('Nessun preferito ancora'), findsNothing);
    expect(find.text('Aggiungi la tua cartella musicale'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('phone: leaving a tab and coming back restores its open page',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const AppShell());
    await tester.tap(_bar('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    expect(find.byType(AllTracksScreen), findsOneWidget);
    await tester.tap(_bar('Home'));
    await _settle(tester);
    await tester.tap(_bar('Libreria'));
    await _settle(tester);
    expect(find.byType(AllTracksScreen), findsOneWidget);
    // Tapping the already-selected tab goes back to its root.
    await tester.tap(_bar('Libreria'));
    await _settle(tester);
    await _settle(tester);
    expect(find.byType(AllTracksScreen), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('phone: leaving a tab and coming back keeps its scroll offset',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 40);
    await h.pump(tester, const AppShell());
    await tester.tap(_bar('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    final list = find.descendant(
        of: find.byType(AllTracksScreen),
        matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axis == Axis.vertical));
    await _settle(tester);
    await _settle(tester);
    tester.state<ScrollableState>(list.first).position.jumpTo(600);
    await tester.pump();
    double offset() => tester.state<ScrollableState>(list.first).position.pixels;
    final before = offset();
    expect(before, greaterThan(0));
    await tester.tap(_bar('Home'));
    await _settle(tester);
    await tester.tap(_bar('Libreria'));
    await _settle(tester);
    expect(offset(), before);
    await h.dispose(tester);
  });

  testWidgets('phone: a root page keeps its scroll offset across tab switches',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 40);
    await h.pump(tester, const AppShell());
    await tester.tap(_bar('Libreria'));
    await _settle(tester);
    final list = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axis == Axis.vertical);
    await tester.drag(list.first, const Offset(0, -500));
    await _settle(tester);
    double offset() => tester.state<ScrollableState>(list.first).position.pixels;
    final before = offset();
    expect(before, greaterThan(0));
    await tester.tap(_bar('Cerca'));
    await _settle(tester);
    await tester.tap(_bar('Memoria'));
    await _settle(tester);
    await tester.tap(_bar('Libreria'));
    await _settle(tester);
    expect(offset(), before);
    await h.dispose(tester);
  });

  testWidgets('phone: the Search tab keeps its query across tab switches',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const AppShell());
    await tester.tap(_bar('Cerca'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Song 2');
    await _settle(tester);
    await tester.tap(_bar('Home'));
    await _settle(tester);
    await tester.tap(_bar('Cerca'));
    await _settle(tester);
    expect(find.text('Song 2'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('sidebar: leaving a tab keeps the page open in it',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('La tua libreria'));
    await _settle(tester);
    await tester.tap(find.descendant(
        of: find.byType(DesktopSidebar), matching: find.text('Preferiti')));
    await _settle(tester);
    expect(find.text('Nessun preferito ancora'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(DesktopSidebar), matching: find.text('Cerca')));
    await _settle(tester);
    // The Library navigator still holds the page: leaving a tab never pops it.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));
    final nav = container
        .read(tabNavigatorKeysProvider)[NavTab.library.index]
        .currentState!;
    expect(nav.canPop(), isTrue);
    await h.dispose(tester);
  });
}
