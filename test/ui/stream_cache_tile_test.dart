import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/stream_providers.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/stream/stream_cache.dart';
import 'package:codecore/ui/screens/settings/stream_cache_tile.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('slider 256 MB-8 GB (default 1 GB), used space, new limit saved on release', (tester) async {
    final h = await Harness.create(tester);
    await h.pump(
      tester,
      const Scaffold(body: SingleChildScrollView(child: StreamCacheTile())),
      extraOverrides: [
        streamCacheProvider.overrideWithValue(StreamCache(Directory.systemTemp)),
        streamCacheUsedProvider.overrideWith((ref) async => 320 * 1024 * 1024),
      ],
    );
    await tester.pump();
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect((slider.min, slider.max, slider.value, slider.divisions), (256.0, 8192.0, 1024.0, 31));
    expect(find.textContaining('320 MB su 1,0 GB'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(3000, 0));
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(StreamCacheTile)));
    expect(container.read(settingsProvider).streamCacheMb, 8192);
  });

  test('Svuota: cache empty but the current track; unplayed shadow rows go, played ones stay', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final tracks = TrackRepository(db);
    final tmp = await Directory.systemTemp.createTemp('sct');
    addTearDown(() => tmp.delete(recursive: true));
    final cache = StreamCache(Directory('${tmp.path}/c'), limitBytes: 1 << 30, freeSpace: () async => null);
    await cache.open();
    const r = YtResult(id: 'x', title: 'T', channel: 'C', duration: Duration(seconds: 9), artists: ['A']);
    final ids = <String, int>{};
    for (final k in ['youtube:a', 'youtube:played', 'youtube:now', 'youtube:queued']) {
      final part = File('${tmp.path}/${k.replaceAll(':', '_')}.m4a.part')..writeAsBytesSync([1, 2, 3]);
      ids[k] = await tracks.upsertStreamRow(k, r, await cache.put(k, part));
    }
    await db.into(db.plays).insert(PlaysCompanion.insert(trackId: ids['youtube:played']!, playedAt: 1));

    await clearStreamCache(cache, tracks, keep: {'youtube:now', 'youtube:queued'});

    expect(await cache.fileFor('youtube:now'), isNotNull);
    expect(await cache.fileFor('youtube:a'), isNull);
    expect(await cache.fileFor('youtube:played'), isNull);
    final left = (await db.select(db.tracks).get()).map((t) => t.id).toSet();
    expect(left, {ids['youtube:played'], ids['youtube:now'], ids['youtube:queued']});
  });
}
