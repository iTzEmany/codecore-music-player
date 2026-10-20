import 'package:codecore/core/frame_stats.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

/// The phase 28 tour (as `scripts/perf_device.py` does on a phone) on 3 000
/// enriched tracks, with the frame times of each scroll printed. In a debug
/// build the times are only comparable with each other; the real numbers come
/// from the profile build on a phone.
const _tracks = 3000;

final _lyrics = List.filled(40, 'Verso della canzone di prova, lungo come uno vero').join('\n');

TracksCompanion _row(int i) => TracksCompanion.insert(
      path: '/m/artist ${i % 150}/album ${i % 300}/song $i.mp3',
      title: 'Brano $i',
      artist: Value('Artista ${i % 150}'),
      album: Value('Album ${i % 300}'),
      albumKey: 'artista ${i % 150}|album ${i % 300}',
      durationMs: Value(120000 + (i % 240) * 1000),
      format: 'mp3',
      sizeBytes: 1000,
      mtimeMs: i,
      addedAt: i,
      lyricsPlain: Value(_lyrics),
      lyricsSynced: Value(_lyrics),
      curiosities: Value(_lyrics),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scrolling the big lists: frame times per screen', (tester) async {
    final app = await AppUnderTest.create();
    await tester.runAsync(() => app.db.batch(
        (b) => b.insertAll(app.db.tracks, [for (var i = 0; i < _tracks; i++) _row(i)])));
    await app.launch(tester);

    final frames = <FrameSample>[];
    void onTimings(List<FrameTiming> t) => frames.addAll(t.map(FrameSample.of));
    SchedulerBinding.instance.addTimingsCallback(onTimings);
    addTearDown(() => SchedulerBinding.instance.removeTimingsCallback(onTimings));

    Future<void> measure(String name, Future<void> Function() action) async {
      await settle(tester, by: const Duration(seconds: 2));
      frames.clear();
      await action();
      await settle(tester, by: const Duration(seconds: 2));
      final s = summarizeFrames(frames);
      // ignore: avoid_print
      print('perf28 $name: ${s.toJson()}');
      expect(s.frames, greaterThan(0), reason: name);
    }

    Future<void> flings() async {
      for (final dy in const <double>[-1200, -1200, -1200, 1200, 1200, 1200]) {
        await tester.fling(find.byType(Scrollable).last, Offset(0, dy), 3000);
        await settle(tester, by: const Duration(milliseconds: 900));
      }
    }

    await tester.tap(find.text('Libreria').last);
    await settle(tester);
    await tester.tap(find.text('Tutti i brani').first);
    await settle(tester);
    await measure('Tutti i brani', flings);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.text('Album').first);
    await settle(tester);
    await measure('Album', flings);

    await tester.tap(find.text('Cerca').last);
    await settle(tester);
    await measure('Ricerca', () async {
      await tester.enterText(find.byType(TextField).first, 'brano 1');
      await settle(tester, by: const Duration(seconds: 1));
      await flings();
    });
    await app.dispose(tester);
  });
}
