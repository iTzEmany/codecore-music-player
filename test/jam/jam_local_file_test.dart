import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/stream/stream_cache.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

JamItem item(String? ref) =>
    JamItem(id: 0, ownerDeviceId: 'me', title: 't', ext: 'mp3', ref: ref);

void main() {
  late Directory tmp;
  late StreamCache cache;
  late AppDatabase db;
  late TrackRepository tracks;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('jam_lf');
    cache = StreamCache(Directory(p.join(tmp.path, 'c')), freeSpace: () async => null);
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
  });

  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  test('yt: gives the cache file, a number the library track, anything else null', () async {
    await cache.open();
    final part = File(p.join(cache.dir.path, 'x.mp3.part'))..writeAsStringSync('abc');
    final f = await cache.put('youtube:abc', part);
    await tracks.upsertBatch([
      TracksCompanion.insert(
          path: '/m/a.mp3', title: 'a', albumKey: 'k', format: 'mp3', sizeBytes: 1, mtimeMs: 1, addedAt: 1),
    ]);
    final id = (await db.select(db.tracks).get()).single.id;

    expect(await jamLocalFile(item('yt:youtube:abc'), cache, tracks), f.path);
    expect(await jamLocalFile(item('yt:youtube:zzz'), cache, tracks), isNull);
    expect(await jamLocalFile(item('$id'), cache, tracks), '/m/a.mp3');
    for (final r in [null, '', 'yt:', 'abc', 'x:1', '../etc']) {
      expect(await jamLocalFile(item(r), cache, tracks), isNull, reason: '$r');
    }
  });

  test('a pinned yt: file survives eviction', () async {
    await cache.open();
    cache.limitBytes = 0;
    final part = File(p.join(cache.dir.path, 'x.mp3.part'))..writeAsStringSync('abc');
    await cache.put('youtube:abc', part, trim: false);
    cache.pin(jamCacheKey(item('yt:youtube:abc'))!);
    await cache.evict();
    expect(await cache.fileFor('youtube:abc'), isNotNull);
    cache.unpin('youtube:abc');
    await cache.evict();
    expect(await cache.fileFor('youtube:abc'), isNull);
  });
}
