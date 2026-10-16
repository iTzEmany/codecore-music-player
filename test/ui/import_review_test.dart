import 'package:codecore/core/import_row.dart';
import 'package:codecore/data/db/app_database.dart'
    show PlaylistImport, PlaylistImportItem, TracksCompanion;
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/providers/import_providers.dart';
import 'package:codecore/providers/library_providers.dart' show ScanState;
import 'package:codecore/providers/online_providers.dart' show EnrichJobState;
import 'package:codecore/ui/screens/import/import_banner.dart';
import 'package:codecore/ui/screens/import/import_review_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<(int, int)> seed(WidgetTester tester, Harness h) async {
  final playlists = PlaylistRepository(h.db);
  final imports = ImportRepository(h.db);
  late int pid, iid;
  await tester.runAsync(() async {
    pid = await playlists.create('Mood');
    iid = await imports.create(playlistId: pid, sourceName: 'Mood', rows: [
      for (var i = 0; i < 4; i++)
        ImportRow(
            index: i,
            title: 'Song $i',
            artists: const ['Band'],
            durationMs: 200000),
    ]);
    await imports.setItem(iid, 0, status: ImportItemStatus.downloaded);
    await imports.setItem(iid, 1,
        status: ImportItemStatus.review,
        candidates: const Value(
            '[{"id":"a","title":"Song 1 (Live)","channel":"Band","durationSec":207,"score":0.6},'
            '{"id":"b","title":"Song 1","channel":"Other","durationSec":201,"score":0.58}]'));
    await imports.setItem(iid, 2, status: ImportItemStatus.notFound);
    await imports.setStatus(iid, ImportStatus.paused);
  });
  return (pid, iid);
}

void main() {
  test('progress counters and activity aggregation', () {
    const imp = ImportProgress(
        id: 3,
        playlistId: 1,
        name: 'Mood',
        total: 10,
        done: 4,
        review: 1,
        missing: 2,
        paused: true);
    expect(imp.fraction, 0.4);
    final s = buildActivity(
      scan: const ScanState(),
      enrich: const EnrichJobState(),
      downloads: const [],
      outgoing: const [],
      imports: const [imp],
    );
    final a = s.running.single;
    expect(a.kind, ActivityKind.import);
    expect(a.paused, isTrue);
    expect(a.cancellable, isTrue);
    expect(a.ref, 3);
  });

  testWidgets('review screen lists candidates and not-found rows; skip works',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final (_, iid) = await seed(tester, h);
    await h.pump(tester, ImportReviewScreen(importId: iid));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Da verificare'), findsOneWidget);
    expect(find.text('Cercato: Song 1 · Band · 3:20'), findsOneWidget);
    expect(find.text('Song 1 (Live)'), findsOneWidget);
    expect(find.textContaining('Other · 3:21 (+1 s)'), findsOneWidget);
    expect(find.text('Non trovati'), findsOneWidget);
    expect(find.text('Cercato: Song 2 · Band · 3:20'), findsOneWidget);
    expect(find.text('Riprova tutti'), findsOneWidget);

    await tester.tap(find.text('Salta').last);
    await tester.pump(const Duration(milliseconds: 300));
    final left = await tester.runAsync(
        () => ImportRepository(h.db).item(iid, 2));
    expect(left!.state, ImportItemStatus.skipped);
    await h.dispose(tester);
  });

  test('progress counts planned rows apart and ignores removed ones', () {
    final imp = PlaylistImport(
        id: 1,
        playlistId: 1,
        sourceName: 'Mood',
        createdAt: 0,
        status: 1,
        sourceKind: 'exportify',
        numberFiles: false,
        linkOnly: false,
        planFirst: true,
        fetchCovers: false);
    PlaylistImportItem item(int i, ImportItemStatus s) => PlaylistImportItem(
        importId: 1, rowIndex: i, title: 't$i', artists: 'a', status: s.index);
    final p = ImportProgress.from(imp, [
      item(0, ImportItemStatus.downloaded),
      item(1, ImportItemStatus.linked),
      item(2, ImportItemStatus.planned),
      item(3, ImportItemStatus.planned),
      item(4, ImportItemStatus.removed),
      item(5, ImportItemStatus.pending),
    ]);
    expect(p.planned, 2);
    expect(p.total, 5, reason: 'the removed row is not part of the import');
    expect(p.done, 4);
  });

  testWidgets('a downloaded file of the wrong length can be kept', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 1);
    final (_, iid) = await seed(tester, h);
    await tester.runAsync(() async {
      final t = await h.db.select(h.db.tracks).getSingle();
      await h.db.update(h.db.tracks).write(
          const TracksCompanion(durationMs: Value(238000)));
      await ImportRepository(h.db).setItem(iid, 3,
          status: ImportItemStatus.review, trackId: Value(t.id));
    });
    await h.pump(tester, ImportReviewScreen(importId: iid));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Durata diversa: 3:58 invece di 3:20'), findsOneWidget);
    await tester.tap(find.text('Tieni questo'));
    await tester.pump(const Duration(milliseconds: 300));
    final kept = await tester.runAsync(() => ImportRepository(h.db).item(iid, 3));
    expect(kept!.state, ImportItemStatus.downloaded);
    await h.dispose(tester);
  });

  testWidgets('playlist banner shows counters and offers resume and review',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final (pid, _) = await seed(tester, h);
    await h.pump(tester, Scaffold(body: ImportBanner(playlistId: pid)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Importazione in pausa: 3/4 · 1 da verificare · 1 non trovati'),
        findsOneWidget);
    expect(find.text('Riprendi'), findsOneWidget);
    expect(find.text('Rivedi'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('banner is hidden when nothing needs attention', (tester) async {
    final h = await Harness.create(tester);
    late int pid;
    await tester.runAsync(() async {
      pid = await PlaylistRepository(h.db).create('Plain');
    });
    await h.pump(tester, Scaffold(body: ImportBanner(playlistId: pid)));
    expect(find.byType(Container), findsNothing);
    await h.dispose(tester);
  });
}
