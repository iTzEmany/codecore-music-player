import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late AppDatabase db;
  late TrackRepository repo;
  late FakeBackend backend;
  late PlayQueue queue;
  late CodecoreAudioHandler handler;
  late List<PlaybackFailure> errors;
  late List<int> ids; // a, b, c
  late int extra; // d, not in the first queue

  Future<int> insert(String name,
      {int ms = 100000, double? gain, int? resume, String album = 'k'}) async {
    await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/$name.mp3',
          title: name,
          albumKey: album,
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          durationMs: Value(ms),
          replayGainDb: Value(gain),
          resumePositionMs: Value(resume),
        ));
    return (await repo.idForPath('/m/$name.mp3'))!;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    backend = FakeBackend();
    queue = PlayQueue(random: Random(5));
    errors = [];
    ids = [await insert('a'), await insert('b', gain: -6), await insert('c')];
    extra = await insert('d');
    handler = CodecoreAudioHandler(backend, queue, repo, onError: errors.add);
  });
  tearDown(() async {
    await handler.dispose();
    await db.close();
  });

  Future<void> startGapless({int at = 0}) async {
    await handler.playQueue(ids, at);
    await handler.setTransition(TransitionMode.gapless);
    await settle();
  }

  test('normal mode never touches the backend window', () async {
    await handler.playQueue(ids, 0);
    handler.playNext(extra);
    handler.pauseAtTrackEnd = true;
    await settle();
    expect(backend.nextCalls, isEmpty);
  });

  test('gapless prepares the next track as soon as it is chosen', () async {
    await startGapless();
    expect(backend.nextPath, '/m/b.mp3');
    expect(backend.nextOverlap, isFalse);
  });

  test('an automatic join changes track without loading anything', () async {
    await startGapless();
    final loads = backend.loaded.length;
    final seen = <int?>[];
    handler.currentTrackStream.listen((t) => seen.add(t?.id));
    backend.advance();
    await settle();
    expect(handler.currentTrack!.title, 'b');
    expect(handler.currentIndex, 1);
    expect(seen, [ids[1]]);
    expect(backend.loaded.length, loads, reason: 'no new load');
    expect(handler.mediaItem.value!.title, 'b');
    expect(backend.nextPath, '/m/c.mp3', reason: 'the window slid on');
    expect(handler.isPlaying, isTrue);
  });

  test('the play count of the new track starts again from the join', () async {
    await startGapless();
    backend.advance();
    await settle();
    backend.posC.add(const Duration(seconds: 60)); // past half of 100 s
    await settle();
    expect((await repo.getById(ids[1]))!.playCount, 1);
    expect((await repo.getById(ids[0]))!.playCount, 0);
  });

  test('ReplayGain follows the join', () async {
    await handler.setNormalize(true);
    await startGapless();
    expect(backend.nextVolume, closeTo(CodecoreAudioHandler.gainFactor(-6), 1e-9));
    backend.advance();
    await settle();
    expect(backend.volumes.last, closeTo(CodecoreAudioHandler.gainFactor(-6), 1e-9));
    expect(backend.nextVolume, 1.0);
  });

  test('shuffle turned on mid-track changes what follows', () async {
    await startGapless();
    await handler.setShuffleMode(AudioServiceShuffleMode.all);
    await settle();
    final announced = queue.peekNext()!;
    final path = (await repo.getById(announced))!.path;
    expect(backend.nextPath, path);
    backend.advance();
    await settle();
    expect(handler.currentTrack!.id, announced);
  });

  test('removing the next track from the queue prepares the one after', () async {
    await startGapless();
    await handler.removeFromQueue(1);
    await settle();
    expect(backend.nextPath, '/m/c.mp3');
  });

  test('«play next» replaces what was prepared', () async {
    await startGapless();
    handler.playNext(extra);
    await settle();
    expect(backend.nextPath, '/m/d.mp3');
    backend.advance();
    await settle();
    expect(handler.currentTrack!.title, 'd');
  });

  test('a join the queue no longer expects plays what the queue says', () async {
    await startGapless();
    handler.playNext(extra);
    backend.advance(); // before the window could be refreshed
    await settle();
    expect(handler.currentTrack!.title, 'd');
    expect(backend.loaded.last, '/m/d.mp3', reason: 'loaded the normal way');
  });

  test('repeat one repeats the same track in the window', () async {
    await startGapless();
    await handler.setRepeatMode(AudioServiceRepeatMode.one);
    await settle();
    expect(backend.nextPath, '/m/a.mp3');
    backend.advance();
    await settle();
    expect(handler.currentTrack!.title, 'a');
    expect(handler.currentIndex, 0);
  });

  test('the end-of-track sleep timer takes the next track away', () async {
    await startGapless();
    handler.pauseAtTrackEnd = true;
    await settle();
    expect(backend.nextPath, isNull);
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(handler.currentTrack!.title, 'b', reason: 'loaded, as in normal mode');
    expect(handler.isPlaying, isFalse);
    expect(handler.pauseAtTrackEnd, isFalse);
  });

  test('turning the timer off puts the next track back', () async {
    await startGapless();
    handler.pauseAtTrackEnd = true;
    await settle();
    handler.pauseAtTrackEnd = false;
    await settle();
    expect(backend.nextPath, '/m/b.mp3');
  });

  test('nothing follows the last track', () async {
    await startGapless(at: 2);
    expect(backend.nextPath, isNull);
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(handler.currentTrack, isNull);
  });

  test('a next track missing from the library: the join falls back to the normal path', () async {
    await handler.playQueue([ids[0], 9999, ids[2]], 0);
    await handler.setTransition(TransitionMode.gapless);
    await settle();
    expect(backend.nextPath, isNull);
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(errors.single.reason, PlaybackFailureReason.notInLibrary);
    expect(backend.loaded.last, '/m/c.mp3');
  });

  test('a track with a saved place is joined through a normal load', () async {
    final book = await insert('book', ms: 3600000, resume: 1800000);
    await handler.playQueue([ids[0], book], 0);
    await handler.setTransition(TransitionMode.gapless);
    await settle();
    expect(backend.nextPath, isNull);
  });

  test('back to normal mid-track empties the window', () async {
    await startGapless();
    await handler.setTransition(TransitionMode.normal);
    await settle();
    expect(backend.nextPath, isNull);
    backend.stateC.add(BackendState.completed);
    await settle();
    expect(handler.currentTrack!.title, 'b');
    expect(backend.loaded.last, '/m/b.mp3');
  });

  test('a manual skip loads the track and prepares the following one', () async {
    await startGapless();
    await handler.skipToNext();
    await settle();
    expect(backend.loaded.last, '/m/b.mp3');
    expect(backend.nextPath, '/m/c.mp3');
    await handler.skipToPrevious();
    await settle();
    expect(backend.loaded.last, '/m/a.mp3');
    expect(backend.nextPath, '/m/b.mp3');
  });

  test('crossfade asks for an overlap, except inside an album when told so', () async {
    final x = await insert('x', album: 'same');
    final y = await insert('y', album: 'same');
    await handler.playQueue([x, y, ids[0]], 0);
    await handler.setTransition(TransitionMode.crossfade);
    await settle();
    expect(backend.nextOverlap, isTrue);
    await handler.setTransition(TransitionMode.crossfade, fadeSameAlbum: true);
    await settle();
    expect(backend.nextOverlap, isFalse, reason: 'x and y share an album');
    backend.advance();
    await settle();
    expect(backend.nextOverlap, isTrue, reason: 'y to a: different albums');
  });
}
