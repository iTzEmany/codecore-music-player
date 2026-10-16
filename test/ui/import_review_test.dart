import 'package:codecore/core/import_row.dart';
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
