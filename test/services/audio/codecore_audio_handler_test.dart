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
  late List<PlaybackFailure> errors;
  late List<int> ids;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    backend = FakeBackend();
    errors = [];
    for (final n in ['a', 'b', 'c']) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/m/$n.mp3',
            title: n,
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
            durationMs: const Value(100000),
          ));
    }
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
    handler = CodecoreAudioHandler(backend, PlayQueue(), repo,
        onError: errors.add);
  });
  tearDown(() async {
    await handler.dispose();
    await db.close();
  });

  test('playQueue loads and plays the chosen track', () async {
    await handler.playQueue(ids, 1);
    await settle();
    expect(backend.loaded.last, '/m/b.mp3');
    expect(handler.isPlaying, true);
    expect(handler.currentTrack!.title, 'b');
  });

  test('completion advances to the next track', () async {
    await handler.playQueue(ids, 0);
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(backend.loaded.last, '/m/b.mp3');
  });

  test('repeat off at last track goes idle', () async {
    await handler.playQueue(ids, 2);
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(handler.currentTrack, isNull);
    expect(handler.isPlaying, false);
    expect(backend.loaded.where((p) => p == '/m/c.mp3').length, 1);
  });

  test('load error reports and skips to next', () async {
    backend.failing.add('/m/b.mp3');
    await handler.playQueue(ids, 1);
    await settle();
    expect(errors.single.title, 'b');
    expect(errors.single.reason, PlaybackFailureReason.fileMissing);
    expect(backend.loaded.last, '/m/c.mp3');
  });

  test('more than 3 consecutive errors stop playback', () async {
    final extra = <int>[];
    for (var i = 0; i < 5; i++) {
      final id = await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/x/$i.mp3',
            title: 'x$i',
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
          ));
      extra.add(id);
      backend.failing.add('/x/$i.mp3');
    }
    await handler.playQueue(extra, 0);
    await settle();
    expect(errors.length, 4);
    expect(handler.currentTrack, isNull);
  });

  test('togglePlayPause follows real backend state', () async {
    await handler.togglePlayPause();
    expect(backend.loaded, isEmpty);
    await handler.playQueue(ids, 0);
    await settle();
    await handler.togglePlayPause();
    await settle();
    expect(handler.isPlaying, false);
    await handler.togglePlayPause();
    await settle();
    expect(handler.isPlaying, true);
  });

  test('play count increments once after half the track', () async {
    await handler.playQueue(ids, 0);
    await settle();
    backend.posC.add(const Duration(seconds: 60));
    backend.posC.add(const Duration(seconds: 61));
    await settle();
    final t = await repo.getById(ids[0]);
    expect(t!.playCount, 1);
    expect(t.lastPlayedAt, isNotNull);
  });

  test('pauseAtTrackEnd loads the next track without playing', () async {
    await handler.playQueue(ids, 0);
    await settle();
    handler.pauseAtTrackEnd = true;
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(handler.currentTrack!.title, 'b');
    expect(handler.isPlaying, false);
    expect(handler.pauseAtTrackEnd, false);
  });
}
