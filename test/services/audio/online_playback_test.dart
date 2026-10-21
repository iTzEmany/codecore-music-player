import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/online_entries.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/audio/stream_address_cache.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

Future<void> settle() => pumpEventQueue();

YtResult result(String id, {String? thumb}) => YtResult(
      id: id,
      title: 'Song $id',
      channel: 'Chan',
      artists: const ['Ann', 'Bob'],
      album: 'Alb',
      duration: const Duration(minutes: 3),
      thumbnailUrl: thumb,
    );

void main() {
  late AppDatabase db;
  late FakeBackend backend;
  late OnlineEntries online;
  late CodecoreAudioHandler handler;
  late List<int> ids;
  late List<PlaybackFailure> failures;
  late List<String> asked;
  final prefetched = <String>[];

  // Every request answers with a fresh address (far from expiring).
  Uri addressFor(String id, int n) {
    final exp = DateTime.now().add(const Duration(hours: 5)).millisecondsSinceEpoch ~/ 1000;
    return Uri.parse('https://stream.test/$id/$n?expire=$exp');
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    backend = FakeBackend();
    online = OnlineEntries();
    failures = [];
    asked = [];
    prefetched.clear();
    for (final n in ['a', 'b']) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/$n.mp3', title: n, albumKey: 'k', format: 'mp3',
          sizeBytes: 1, mtimeMs: 1, addedAt: 1, durationMs: const Value(200000)));
    }
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
    final cache = _SpyCache((r) async {
      asked.add(r.id);
      return addressFor(r.id, asked.length);
    }, prefetched);
    handler = CodecoreAudioHandler(backend, PlayQueue(), TrackRepository(db),
        onError: failures.add,
        history: PlayHistoryRepository(db),
        online: online,
        addresses: cache);
  });
  tearDown(() async {
    await handler.dispose();
    await db.close();
  });

  test('an online entry loads the address, not a file', () async {
    final id = online.register(result('v1'));
    await handler.playQueue([id], 0);
    expect(backend.loaded, isEmpty);
    expect(backend.loadedUris.single.uri.host, 'stream.test');
    expect(backend.loadedUris.single.uri.path, '/v1/1');
    expect(handler.currentTrack?.id, id);
  });

  test('an expired address is dropped and asked for once more', () async {
    final id = online.register(result('v1'));
    backend.expiring.add(addressFor('v1', 1).toString());
    await handler.playQueue([id], 0);
    expect(asked, ['v1', 'v1']);
    expect(backend.loadedUris.single.uri.path, '/v1/2');
    expect(failures, isEmpty);
  });

  test('two failures skip to the next track with the online reason', () async {
    final id = online.register(result('v1'));
    backend.expiring.addAll([addressFor('v1', 1).toString(), addressFor('v1', 2).toString()]);
    await handler.playQueue([id, ids[0]], 0);
    await settle();
    expect(failures.single.reason, PlaybackFailureReason.onlineUnavailable);
    expect(backend.loaded, ['/m/a.mp3']);
    expect(handler.currentTrack?.id, ids[0]);
  });

  test('an entry missing from the registry is skipped as not in library', () async {
    await handler.playQueue([-99, ids[0]], 0);
    await settle();
    expect(failures.single.reason, PlaybackFailureReason.notInLibrary);
    expect(handler.currentTrack?.id, ids[0]);
  });

  test('listening to an online entry to the end writes no history and no count', () async {
    final id = online.register(result('v1'));
    await handler.playQueue([id], 0);
    for (var s = 0; s <= 100; s += 5) {
      backend.posC.add(Duration(seconds: s));
      await Future<void>.delayed(Duration.zero);
    }
    backend.stateC.add(BackendState.paused);
    await settle();
    expect(await db.select(db.plays).get(), isEmpty);
    expect((await db.select(db.tracks).get()).every((t) => t.playCount == 0), isTrue);
  });

  test('the notification item comes from the synthetic track', () async {
    final id = online.register(result('v1',
        thumb: 'https://lh3.googleusercontent.com/x=w60-h60-l90-rj'));
    await handler.playQueue([id], 0);
    final item = handler.mediaItem.value!;
    expect(item.id, 'online:v1');
    expect(item.title, 'Song v1');
    expect(item.artist, 'Ann, Bob');
    expect(item.album, 'Alb');
    expect(item.artUri.toString(), 'https://lh3.googleusercontent.com/x=w544-h544-l90-rj');
    expect(item.extras, {'online': true});
  });

  test('the address of the next online entry is asked ahead of time', () async {
    final id = online.register(result('v2'));
    await handler.playQueue([ids[0], id], 0);
    await settle();
    expect(prefetched, ['v2']);
  });

  test('insertAt and removeQueueId change the queue and tell the listeners', () async {
    final id = online.register(result('v2'));
    await handler.playQueue([ids[0], ids[1]], 0);
    var changes = 0;
    final sub = handler.queueChanges.listen((_) => changes++);
    handler.insertAt(1, id);
    await settle();
    expect(handler.queueIds, [ids[0], id, ids[1]]);
    await handler.removeQueueId(id);
    await settle();
    expect(handler.queueIds, [ids[0], ids[1]]);
    expect(changes, 2);
    expect(handler.sourceIds, [ids[0], ids[1]]);
    await sub.cancel();
  });
}

class _SpyCache extends StreamAddressCache {
  _SpyCache(super.resolve, this.log);
  final List<String> log;

  @override
  void prefetch(YtResult r) {
    log.add(r.id);
    super.prefetch(r);
  }
}
