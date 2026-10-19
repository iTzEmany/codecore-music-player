import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/smart_playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/ui/screens/library/library_screen.dart';
import 'package:codecore/ui/screens/smart/smart_playlist_editor.dart';
import 'package:codecore/ui/screens/smart/smart_playlist_screen.dart';
import 'package:codecore/ui/widgets/smart_cover.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// One turn of the real event loop (not real time) lets drift finish what a
/// `runAsync` write started; everything else runs on the test clock.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _row(String title) =>
    find.descendant(of: find.byType(TrackRow), matching: find.text(title));

void main() {
  late Harness h;
  late SmartPlaylistRepository repo;
  late List<Track> tracks;

  Future<void> open(WidgetTester tester, Widget Function(Harness h) page) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 4);
    repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
    tracks = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
    await h.pump(tester, page(h));
    await _settle(tester);
  }

  Future<int> make(WidgetTester tester, String name, String rules,
          {SmartSort sort = SmartSort.title, int? limit}) async =>
      (await tester.runAsync(() => repo.create(name: name, rules: rules, sort: sort, limit: limit)))!;

  group('the page', () {
    testWidgets('lists what the rules select and says it is a smart playlist', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
      tracks = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
      final id = await make(tester, 'Album uno', 'album:"Album 1"');
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, SmartPlaylistScreen(id: id));
      await _settle(tester);
      expect(find.text('Album uno'), findsWidgets);
      expect(find.text('album:"Album 1"'), findsOneWidget);
      expect(find.text('Playlist intelligente · 2 brani'), findsOneWidget);
      expect(_row('Song 1'), findsOneWidget);
      expect(_row('Song 3'), findsOneWidget);
      expect(_row('Song 0'), findsNothing);
      expect(find.byType(SmartCover), findsOneWidget);
      expect(find.text('Aggiungi brani'), findsNothing, reason: 'read-only');
      expect(find.byType(ReorderableDragStartListener), findsNothing);
      await h.dispose(tester);
    });

    testWidgets('it changes by itself: a favourite joins a «preferiti» list', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
      tracks = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
      final id = await make(tester, 'Cuori', 'preferiti');
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, SmartPlaylistScreen(id: id));
      await _settle(tester);
      expect(_row('Song 2'), findsNothing);
      await tester.runAsync(() => TrackRepository(h.db).setFavorite(tracks[2].id, true));
      await _settle(tester);
      expect(_row('Song 2'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('tapping a track plays the list as it was at that moment', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
      final id = await make(tester, 'Tutti', 'artista:artist');
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, SmartPlaylistScreen(id: id));
      await _settle(tester);
      await tester.tap(_row('Song 2'));
      await _settle(tester);
      expect(h.handler.currentTrack?.title, 'Song 2');
      expect(h.handler.queueIds, hasLength(4));
      await h.dispose(tester);
    });

    testWidgets('«Converti in playlist normale» copies the current list and keeps the rule', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
      tracks = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
      final id = await make(tester, 'Pari', 'album:"Album 0"');
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, SmartPlaylistScreen(id: id));
      await _settle(tester);
      await tester.tap(find.byTooltip('Altre azioni'));
      await _settle(tester);
      await tester.tap(find.text('Converti in playlist normale'));
      await _settle(tester);
      final plain = (await tester.runAsync(() => PlaylistRepository(h.db).watchAll().first))!.single;
      expect(plain.playlist.name, 'Pari');
      final copied = (await tester.runAsync(() => PlaylistRepository(h.db).watchTracks(plain.playlist.id).first))!;
      expect(copied.map((t) => t.title), ['Song 0', 'Song 2']);
      expect((await tester.runAsync(() => repo.get(id)))!.rules, 'album:"Album 0"', reason: 'the rule stays');
      await h.dispose(tester);
    });

    testWidgets('deleting asks first, and only the rule goes', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
      final id = await make(tester, 'Via', '');
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, Scaffold(body: Builder(builder: (c) => TextButton(
          onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => SmartPlaylistScreen(id: id))),
          child: const Text('open')))));
      await tester.tap(find.text('open'));
      await _settle(tester);
      await tester.tap(find.byTooltip('Altre azioni'));
      await _settle(tester);
      await tester.tap(find.text('Elimina'));
      await _settle(tester);
      expect(find.text('Eliminare «Via»?'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await _settle(tester);
      expect(await tester.runAsync(() => repo.get(id)), isNotNull);
      await tester.tap(find.byTooltip('Altre azioni'));
      await _settle(tester);
      await tester.tap(find.text('Elimina'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
      await _settle(tester);
      expect(await tester.runAsync(() => repo.get(id)), isNull);
      expect((await tester.runAsync(() => h.db.select(h.db.tracks).get()))!, hasLength(4));
      await h.dispose(tester);
    });
  });

  group('the editor', () {
    testWidgets('a live count under the rules, and the parser\'s remarks', (tester) async {
      await open(tester, (_) => const SmartPlaylistEditor());
      await tester.enterText(find.widgetWithText(TextField, 'Regole'), 'album:"Album 1"');
      await _settle(tester);
      expect(find.text('2 brani'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Regole'), 'colore:rosso');
      await _settle(tester);
      expect(find.textContaining('Non capisco «colore:rosso»'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Regole'), '');
      await _settle(tester);
      expect(find.text('Senza regole la playlist contiene tutta la libreria.'), findsOneWidget);
      expect(find.text('4 brani'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('a limit caps the count shown', (tester) async {
      await open(tester, (_) => const SmartPlaylistEditor());
      await tester.enterText(find.widgetWithText(TextField, 'Limite di brani (facoltativo)'), '3');
      await _settle(tester);
      expect(find.text('3 brani'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('a template fills the name, the rules, the order and the limit', (tester) async {
      await open(tester, (_) => const SmartPlaylistEditor());
      await tester.tap(find.text('I più ascoltati'));
      await _settle(tester);
      expect(find.widgetWithText(TextField, 'I più ascoltati'), findsOneWidget, reason: 'the name');
      expect(find.text('ascolti>0'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Più ascoltati'), findsOneWidget, reason: 'the order');
      await h.dispose(tester);
    });

    testWidgets('saving needs a name, then creates the playlist with the rules in canonical form', (tester) async {
      await open(tester, (_) => Scaffold(body: Builder(builder: (c) => TextButton(
          onPressed: () => Navigator.of(c).push(MaterialPageRoute<bool>(builder: (_) => const SmartPlaylistEditor())),
          child: const Text('open')))));
      await tester.tap(find.text('open'));
      await _settle(tester);
      await tester.tap(find.text('Salva'));
      await _settle(tester);
      expect(find.text('Scrivi un nome'), findsOneWidget);
      expect(await tester.runAsync(() => repo.getAll()), isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Mia');
      await tester.enterText(find.widgetWithText(TextField, 'Regole'), 'ARTIST:artist year:1990..');
      await tester.tap(find.text('Salva'));
      await _settle(tester);
      final saved = (await tester.runAsync(() => repo.getAll()))!.single;
      expect(saved.name, 'Mia');
      expect(saved.rules, 'artista:artist anno:1990..');
      expect(find.text('open'), findsOneWidget, reason: 'the editor closed');
      await h.dispose(tester);
    });

    testWidgets('editing starts from what was saved and updates it', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
      final id = await make(tester, 'Prima', 'preferiti', sort: SmartSort.year, limit: 7);
      final existing = (await tester.runAsync(() => repo.get(id)))!;
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, Scaffold(body: Builder(builder: (c) => TextButton(
          onPressed: () => Navigator.of(c).push(MaterialPageRoute<bool>(builder: (_) => SmartPlaylistEditor(existing: existing))),
          child: const Text('open')))));
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.text('Modifica playlist intelligente'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Prima'), findsOneWidget);
      expect(find.text('preferiti'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Prima'), 'Dopo');
      await tester.enterText(find.widgetWithText(TextField, '7'), '');
      await tester.tap(find.text('Salva'));
      await _settle(tester);
      final p = (await tester.runAsync(() => repo.get(id)))!;
      expect((p.name, p.limitCount, p.sort), ('Dopo', null, 'year'));
      await h.dispose(tester);
    });
  });

  group('the library', () {
    testWidgets('shows smart playlists beside the others, with their own cover, and opens them', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      repo = SmartPlaylistRepository(h.db, TrackRepository(h.db));
      await make(tester, 'Intelligente', 'preferiti');
      await tester.runAsync(() => PlaylistRepository(h.db).create('Normale'));
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, const Scaffold(body: LibraryScreen()));
      await _settle(tester);
      expect(find.text('Intelligente'), findsOneWidget);
      expect(find.text('Playlist intelligente'), findsOneWidget);
      expect(find.text('Normale'), findsOneWidget);
      expect(find.byType(SmartCover), findsOneWidget);
      await tester.tap(find.text('Intelligente'));
      await _settle(tester);
      expect(find.byType(SmartPlaylistScreen), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('the + menu offers a new smart playlist', (tester) async {
      h = await Harness.create(tester, tracks: 4);
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await h.pump(tester, const Scaffold(body: LibraryScreen()));
      await _settle(tester);
      await tester.tap(find.byTooltip('Nuova playlist'));
      await _settle(tester);
      await tester.tap(find.text('Nuova playlist intelligente'));
      await _settle(tester);
      expect(find.byType(SmartPlaylistEditor), findsOneWidget);
      await h.dispose(tester);
    });
  });
}
