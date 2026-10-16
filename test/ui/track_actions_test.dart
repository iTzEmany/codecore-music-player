import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/ui/screens/now_playing/queue_sheet.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('long press → menu groups → «Vai all\'album» opens the album',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    await tester.longPress(find.text('Song 1').first);
    await _settle(tester);
    // Grouped menu under the track header.
    expect(find.text('Riproduci dopo'), findsOneWidget);
    expect(find.text('Vai all’album'), findsOneWidget);
    expect(find.text('Vai all’artista'), findsOneWidget);
    await tester.tap(find.text('Vai all’album'));
    await _settle(tester);
    await _settle(tester);
    expect(find.byType(AlbumDetailScreen), findsOneWidget);
    expect(find.text('Libreria'), findsWidgets); // bottom bar still there
    await h.dispose(tester);
  });

  testWidgets('a track with a bookmark says where it resumes and offers a restart',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 3);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    final marked = rows!.firstWhere((t) => t.title == 'Song 1');
    await tester.runAsync(() => TrackRepository(h.db)
        .setResumePosition(marked.id, const Duration(minutes: 42, seconds: 10).inMilliseconds));
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);

    expect(find.textContaining('riprendi da 42:10'), findsOneWidget);
    await tester.longPress(find.text('Song 1').first);
    await _settle(tester);
    expect(find.text('Ricomincia dall’inizio'), findsOneWidget);
    await tester.tap(find.text('Ricomincia dall’inizio'));
    await _settle(tester);
    final after = await tester
        .runAsync(() => TrackRepository(h.db).getById(marked.id));
    expect(after!.resumePositionMs, isNull, reason: 'the bookmark is cleared');
    expect(h.handler.currentTrack?.id, marked.id, reason: 'and it plays from the start');
    await h.dispose(tester);
  });

  testWidgets('a track without a bookmark has no restart entry', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    await tester.longPress(find.text('Song 1').first);
    await _settle(tester);
    expect(find.text('Ricomincia dall’inizio'), findsNothing);
    expect(find.textContaining('riprendi da'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('queue: now playing and next sections, no played tracks',
      (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 4);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester
        .runAsync(() => h.handler.playQueue([for (final t in rows!) t.id], 1));
    await h.pump(
        tester,
        Scaffold(
            body: QueueSheet(scrollController: ScrollController())));
    await _settle(tester);
    expect(find.text('In riproduzione'), findsOneWidget);
    expect(find.text('Prossimi'), findsOneWidget);
    expect(find.text('Svuota'), findsOneWidget);
    expect(find.text('Song 0'), findsNothing); // already played
    expect(find.text('Song 1'), findsOneWidget);
    expect(find.text('Song 3'), findsOneWidget);
    await h.dispose(tester);
  });
}
