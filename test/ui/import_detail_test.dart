import 'package:codecore/core/import_row.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/providers/import_providers.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/ui/screens/import/import_detail_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('one list for all the blocks, each song with its phase, and the filters', (tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final repo = ImportRepository(h.db);
    late int first, second;
    await tester.runAsync(() async {
      final pl = await h.db.into(h.db.playlists).insert(PlaylistsCompanion.insert(name: 'Mood', createdAt: 0));
      first = await repo.create(playlistId: pl, sourceName: 'Mood (1/2)', rows: const [
        ImportRow(index: 0, title: 'Uno', artists: ['Band']),
        ImportRow(index: 1, title: 'Due', artists: ['Band']),
      ]);
      second = await repo.create(playlistId: pl, sourceName: 'Mood (2/2)', rows: const [
        ImportRow(index: 2, title: 'Tre', artists: ['Band']),
        ImportRow(index: 3, title: 'Quattro', artists: ['Band']),
      ]);
      await repo.setStatus(first, ImportStatus.finished);
      await repo.setItem(first, 0, status: ImportItemStatus.downloaded);
      await repo.setItem(first, 1, status: ImportItemStatus.notFound);
      await repo.setStatus(second, ImportStatus.running);
      await repo.setItem(second, 2, status: ImportItemStatus.queued, videoId: const Value('v'));
    });
    await h.pump(
      tester,
      ImportDetailScreen(importId: second),
      extraOverrides: [
        importStepsProvider.overrideWith((ref) => Stream.value({(second, 3): ImportStepKind.searching})),
        importDownloadsProvider.overrideWithValue({
          (second, 2): DownloadItem(
            id: 1,
            result: const YtResult(id: 'v', title: 'Tre', channel: 'Band', duration: null),
            status: DownloadStatus.downloading,
            progress: 0.45,
            tag: importTag(second, 2),
          ),
        }),
      ],
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.text('Mood'), findsOneWidget, reason: 'the import, not the block');
    expect(find.text('Band · Scaricato'), findsOneWidget);
    expect(find.text('Band · Non trovato'), findsOneWidget);
    expect(find.text('Band · Download 45 %'), findsOneWidget);
    expect(find.text('Band · In ricerca…'), findsOneWidget);
    expect(find.text('In corso (2)'), findsOneWidget);
    expect(find.text('Da sistemare (1)'), findsOneWidget);

    await tester.ensureVisible(find.text('Da sistemare (1)'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Da sistemare (1)'));
    await tester.pump();
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Uno'), findsNothing);
    await h.dispose(tester);
  });
}
