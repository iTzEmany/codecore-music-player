import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late AppDatabase db;
  late TrackRepository repo;
  late FakeBackend backend;
  late CodecoreAudioHandler handler;
  late List<int> heard;
  late int episodeId, otherEpisodeId, songId;
  const ten = 10 * 60 * 1000; // a 10-minute episode: under the 20-minute rule for music

  Future<int> add(String name, {int kind = 0, int ms = ten}) => db.into(db.tracks).insert(
      TracksCompanion.insert(
        path: '/m/$name.mp3', title: name, albumKey: 'k$kind', format: 'mp3',
        sizeBytes: 1, mtimeMs: 1, addedAt: 1, durationMs: Value(ms), kind: Value(kind)));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    backend = FakeBackend();
    heard = [];
    episodeId = await add('ep1', kind: 1);
    otherEpisodeId = await add('ep2', kind: 1);
    songId = await add('song');
    handler = CodecoreAudioHandler(backend, PlayQueue(), repo, onError: (_) {}, onEpisodeHeard: heard.add);
  });
  tearDown(() async {
    await handler.dispose();
    await db.close();
  });

  Future<int?> saved(int id) async => (await repo.getById(id))!.resumePositionMs;
  Future<void> at(Duration p) async {
    backend.posC.add(p);
    await settle();
  }

  test('a short episode is bookmarked while playing (a song of that length would not be)', () async {
    await handler.playQueue([episodeId], 0);
    await at(const Duration(seconds: 5));
    expect(await saved(episodeId), isNull, reason: 'the first 10 seconds are not a place to come back to');
    await at(const Duration(minutes: 3));
    expect(await saved(episodeId), const Duration(minutes: 3).inMilliseconds);

    await handler.playQueue([songId], 0);
    await at(const Duration(minutes: 3));
    expect(await saved(songId), isNull);
  });

  test('pausing keeps the exact place, and the next play starts 5 seconds earlier', () async {
    await handler.playQueue([episodeId], 0);
    await at(const Duration(minutes: 4, seconds: 20));
    await handler.pause();
    await settle();
    expect(await saved(episodeId), const Duration(minutes: 4, seconds: 20).inMilliseconds);

    await handler.playQueue([episodeId], 0);
    await settle();
    expect(backend.seeks.last, const Duration(minutes: 4, seconds: 15));
  });

  test('it counts as heard once, past 95 %, and the bookmark is cleared', () async {
    await handler.playQueue([episodeId], 0);
    await at(const Duration(minutes: 9)); // 90 %
    expect(heard, isEmpty);
    await at(const Duration(minutes: 9, seconds: 40)); // 96.7 %
    await at(const Duration(minutes: 9, seconds: 50));
    await handler.pause();
    await settle();
    expect(heard, [episodeId], reason: 'reported once, not at every save');
    expect(await saved(episodeId), isNull);
  });

  test('playing it to the end counts as heard, even if no save came near the end', () async {
    await handler.playQueue([episodeId, songId], 0);
    await at(const Duration(minutes: 2));
    // The last 15-second save was a while ago; then the end arrives.
    backend.posC.add(const Duration(minutes: 9, seconds: 59));
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(heard, [episodeId]);
    expect(await saved(episodeId), isNull);
  });

  test('music never reports anything, however it ends', () async {
    await handler.playQueue([songId], 0);
    await at(const Duration(minutes: 9, seconds: 50));
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(heard, isEmpty);
  });

  test('another episode is reported on its own', () async {
    await handler.playQueue([episodeId, otherEpisodeId], 0);
    await at(const Duration(minutes: 9, seconds: 50));
    await handler.skipToNext();
    await settle();
    await at(const Duration(minutes: 9, seconds: 55));
    await handler.pause();
    await settle();
    expect(heard, [episodeId, otherEpisodeId]);
  });

  test('a callback that throws does not break playback', () async {
    await handler.dispose();
    handler = CodecoreAudioHandler(backend, PlayQueue(), repo,
        onError: (_) {}, onEpisodeHeard: (_) => throw StateError('db closed'));
    await handler.playQueue([episodeId], 0);
    await at(const Duration(minutes: 9, seconds: 50));
    await handler.pause();
    await settle();
    expect(handler.playbackState.value.playing, isFalse);
  });
}
