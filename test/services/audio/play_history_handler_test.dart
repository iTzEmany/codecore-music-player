import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

/// Lets every pending async step run, without waiting on the wall clock.
Future<void> settle() => pumpEventQueue();

class _BrokenHistory extends PlayHistoryRepository {
  _BrokenHistory(super.db);
  @override
  Future<int> start(int trackId, int playedAt,
          {int? context, String? contextName, int msPlayed = 0}) =>
      Future<int>.error(StateError('disk full'));
}

void main() {
  late AppDatabase db;
  late FakeBackend backend;
  late CodecoreAudioHandler handler;
  late List<int> ids;

  Future<void> build({PlayHistoryRepository? history}) async {
    handler = CodecoreAudioHandler(backend, PlayQueue(), TrackRepository(db),
        onError: (_) {}, history: history ?? PlayHistoryRepository(db));
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    backend = FakeBackend();
    for (final n in ['a', 'b']) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/m/$n.mp3', title: n, albumKey: 'k', format: 'mp3',
            sizeBytes: 1, mtimeMs: 1, addedAt: 1, durationMs: const Value(200000)));
    }
    ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
    await build();
  });
  tearDown(() async {
    await handler.dispose();
    await db.close();
  });

  /// One position event per second of music, from [from] to [to].
  Future<void> play(int from, int to, {int step = 1}) async {
    for (var s = from; s <= to; s += step) {
      backend.posC.add(Duration(seconds: s));
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<List<Play>> plays() => db.select(db.plays).get();

  test('forty seconds of play make one row with the time really played', () async {
    await handler.playQueue(ids, 0);
    await play(0, 40);
    await settle();
    final row = (await plays()).single;
    expect(row.trackId, ids[0]);
    await handler.skipToNext();
    await settle();
    expect((await plays()).single.msPlayed, closeTo(40000, 500));
  });

  test('a seek forward does not inflate the time', () async {
    await handler.playQueue(ids, 0);
    await play(0, 10);
    await play(100, 110); // jumped ahead 90 s
    await handler.skipToNext();
    await settle();
    final row = (await plays()).single;
    expect(row.msPlayed, closeTo(20000, 500), reason: '10 s + 10 s, not 110');
  });

  test('a track skipped after ten seconds leaves no row', () async {
    await handler.playQueue(ids, 0);
    await play(0, 10);
    await handler.skipToNext();
    await settle();
    expect(await plays(), isEmpty);
  });

  test('pausing writes the time so far', () async {
    await handler.playQueue(ids, 0);
    await play(0, 35);
    await handler.pause();
    await settle();
    expect((await plays()).single.msPlayed, closeTo(35000, 500));
  });

  test('time not spent playing is not counted', () async {
    await handler.playQueue(ids, 0);
    await play(0, 20);
    await handler.pause();
    await settle();
    await play(21, 29); // events while paused (a scrub): not playing
    await handler.play();
    await settle();
    await play(30, 40);
    await handler.skipToNext();
    await settle();
    expect((await plays()).single.msPlayed, closeTo(30000, 1200), reason: '20 s + 10 s (not the 9 s of scrubbing)');
  });

  test('at 2× the time is wall-clock time, half of the music', () async {
    await handler.playQueue(ids, 0);
    await handler.setSpeed(2);
    await play(0, 60, step: 2); // 60 s of music in 30 s
    await handler.skipToNext();
    await settle();
    expect((await plays()).single.msPlayed, closeTo(30000, 800));
  });

  test('the context the queue came from is recorded', () async {
    handler.setPlayContext(2, 'Mix');
    await handler.playQueue(ids, 0);
    await play(0, 35);
    await settle();
    final row = (await plays()).single;
    expect(row.context, 2);
    expect(row.contextName, 'Mix');
  });

  test('with the history switched off nothing is written, but the play count still grows', () async {
    handler.recordHistory = false;
    await handler.playQueue(ids, 0);
    await play(0, 35);
    await handler.skipToNext();
    await settle();
    expect(await plays(), isEmpty);
    expect((await TrackRepository(db).getById(ids[0]))!.playCount, 1);
  });

  test('the next track gets its own row, and the first keeps its own time', () async {
    await handler.playQueue(ids, 0);
    await play(0, 35);
    backend.stateC.add(BackendState.completed);
    await settle();
    await play(0, 32);
    await handler.pause();
    await settle();
    final rows = await plays();
    expect(rows.map((r) => r.trackId), [ids[0], ids[1]]);
    expect(rows[0].msPlayed, closeTo(35000, 500));
    expect(rows[1].msPlayed, closeTo(32000, 500));
  });

  test('a history that fails never stops the music', () async {
    await handler.dispose();
    await build(history: _BrokenHistory(db));
    await handler.playQueue(ids, 0);
    await play(0, 35);
    await settle();
    expect(handler.isPlaying, isTrue);
    expect((await TrackRepository(db).getById(ids[0]))!.playCount, 1);
    await handler.skipToNext();
    await settle();
    expect(handler.currentTrack!.title, 'b');
  });

  test('a podcast episode leaves no trace in the history, however long it plays', () async {
    final epId = await db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/app/podcasts/1/e.mp3', title: 'Episode', albumKey: 'k2', format: 'mp3',
        sizeBytes: 1, mtimeMs: 1, addedAt: 1, durationMs: const Value(2000000),
        kind: const Value(1)));
    await handler.playQueue([epId], 0);
    await play(0, 60);
    await settle();
    expect(await plays(), isEmpty);
    // The next music track still counts.
    await handler.playQueue(ids, 0);
    await play(0, 40);
    await settle();
    expect((await plays()).single.trackId, ids[0]);
  });
}
