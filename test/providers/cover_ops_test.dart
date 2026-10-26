import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/cover_ops.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:codecore/services/tags/tag_reader.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _NoTags implements TagReader {
  @override
  Future<TagInfo> read(String path, {bool withCover = true}) async => const TagInfo();
}

void main() {
  late Directory tmp;
  late AppDatabase db;
  late TrackRepository tracks;
  late CoverStore store;
  late ProviderContainer c;
  late CoverOps ops;
  late String original;

  Future<Track> row(int i) async => (await tracks.byPath('/m/$i.mp3'))!;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('cops');
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    store = CoverStore(Directory(p.join(tmp.path, 'covers')));
    original = (await store.saveFromBytes('alb', [1, 2, 3], 'image/jpeg'))!;
    await tracks.upsertBatch([
      for (final i in [1, 2, 3])
        TracksCompanion.insert(
          path: '/m/$i.mp3',
          title: 't$i',
          albumKey: 'alb',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          hasCover: const Value(true),
          coverKey: Value(original),
        ),
    ]);
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      coverStoreProvider.overrideWithValue(store),
      tagReaderProvider.overrideWithValue(_NoTags()),
    ]);
    ops = c.read(coverOpsProvider);
  });
  tearDown(() async {
    c.dispose();
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  test('album cover changes the tracks without their own, restore brings the original back', () async {
    expect(await ops.setTrackCover((await row(3)).id, [9, 9], 'image/png'), isTrue);
    final own = (await row(3)).coverKey!;
    expect(await ops.setAlbumCover('alb', [7, 7], 'image/png'), isTrue);

    final a = await row(1), b = await row(2), mine = await row(3);
    expect(a.coverKey, b.coverKey);
    expect([a.coverSource, b.coverSource, mine.coverSource], [1, 1, 2]);
    expect(mine.coverKey, own);

    await ops.restoreAlbumCover('alb');
    expect([(await row(1)).coverKey, (await row(2)).coverKey], [original, original]);
    expect((await row(1)).coverSource, 0);
    expect((await row(3)).coverKey, own);
    expect(store.fileFor(a.coverKey!), isNull, reason: 'the album pick is gone from disk');

    await ops.restoreTrackCover(mine.id);
    final back = await row(3);
    expect([back.coverKey, back.coverSource], [original, 0]);
    expect(store.fileFor(own), isNull);
  });

  test('a second pick deletes the first hand-picked file and its thumbnail, never the original', () async {
    final id = (await row(1)).id;
    await ops.setTrackCover(id, [1], null);
    final first = (await row(1)).coverKey!;
    File(p.join(store.dir.path, CoverStore.thumbName(first))).writeAsBytesSync([0]);
    await ops.setTrackCover(id, [2], null);

    expect(store.fileFor(first), isNull);
    expect(File(p.join(store.dir.path, CoverStore.thumbName(first))).existsSync(), isFalse);
    expect(store.fileFor(original), isNotNull);
    expect(store.fileFor((await row(1)).coverKey!), isNotNull);
  });

  test('empty or too large bytes are not saved', () async {
    expect(await ops.setTrackCover((await row(1)).id, [], null), isFalse);
    expect(await ops.setAlbumCover('alb', List.filled(CoverStore.maxBytes + 1, 0), null), isFalse);
    expect((await row(1)).coverSource, 0);
  });
}
