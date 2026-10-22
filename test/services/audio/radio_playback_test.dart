import 'package:audio_service/audio_service.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/online_entries.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

RadioStation station(String id, {String? url}) => RadioStation(
      id: id,
      name: 'Radio $id',
      streamUrl: url ?? 'http://radio.test/$id',
      faviconUrl: 'http://radio.test/$id.png',
    );

void main() {
  late AppDatabase db;
  late FakeBackend backend;
  late OnlineEntries online;
  late CodecoreAudioHandler handler;
  late List<PlaybackFailure> failures;
  late List<String> started;
  late int libraryId;
  late DateTime now;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/m/a.mp3', title: 'a', albumKey: 'k', format: 'mp3',
        sizeBytes: 1, mtimeMs: 1, addedAt: 1, durationMs: const Value(200000)));
    libraryId = (await db.select(db.tracks).get()).single.id;
    backend = FakeBackend();
    online = OnlineEntries();
    failures = [];
    started = [];
    now = DateTime(2026, 1, 1);
    handler = CodecoreAudioHandler(backend, PlayQueue(), TrackRepository(db),
        onError: failures.add,
        history: PlayHistoryRepository(db),
        online: online,
        onRadioStart: (s) => started.add(s.id),
        clock: () => now);
  });
  tearDown(() async {
    await handler.dispose();
    await db.close();
  });

  test('a station loads its address, counts the start once and is live', () async {
    await handler.playStations([station('a'), station('b')], 0);
    expect(backend.loaded, isEmpty);
    expect(backend.loadedUris.single.uri.toString(), 'http://radio.test/a');
    expect(started, ['a']);
    final item = handler.mediaItem.value!;
    expect(item.title, 'Radio a');
    expect(item.duration, isNull);
    expect(item.artUri.toString(), 'http://radio.test/a.png');
    final ps = handler.playbackState.value;
    expect(ps.systemActions, isEmpty);
    expect(handler.isRadio, isTrue);
    // Pause and resume is not a new start.
    await handler.pause();
    await handler.play();
    expect(started, ['a']);
  });

  test('the ICY title becomes the title, the station the artist', () async {
    await handler.playStations([station('a')], 0);
    backend.titleC.add('Queen - Radio Ga Ga');
    await pumpEventQueue();
    expect(handler.mediaItem.value!.title, 'Queen - Radio Ga Ga');
    expect(handler.mediaItem.value!.artist, 'Radio a');
    expect(handler.onAir, 'Queen - Radio Ga Ga');
    backend.titleC.add('Radio a');
    await pumpEventQueue();
    expect(handler.mediaItem.value!.title, 'Radio a');
    expect(handler.onAir, isNull);
  });

  test('next and previous move between the stations, the list wraps', () async {
    await handler.playStations([station('a'), station('b'), station('c')], 1);
    expect(started, ['b']);
    await handler.skipToNext();
    expect(backend.loadedUris.last.uri.path, '/c');
    await handler.skipToNext();
    expect(backend.loadedUris.last.uri.path, '/a');
    await handler.skipToPrevious();
    expect(backend.loadedUris.last.uri.path, '/c');
    expect(started, ['b', 'c', 'a', 'c']);
  });

  test('previous goes to the previous station even after minutes, and wraps', () async {
    await handler.playStations([station('a'), station('b'), station('c')], 1);
    backend.posC.add(const Duration(seconds: 90));
    await pumpEventQueue();
    await handler.skipToPrevious();
    expect(backend.loadedUris.last.uri.path, '/a');
    await handler.skipToPrevious(); // first station: the last one, not a restart
    expect(backend.loadedUris.last.uri.path, '/c');
    expect(handler.queueIds, hasLength(3));
    expect(handler.hasNext, isTrue);
  });

  test('a manual station is reported too: the caller skips the click', () async {
    await handler.playStations([station('manual:x')], 0);
    expect(started, ['manual:x']);
  });

  test('no plays, no count, even after listening for minutes', () async {
    await handler.playStations([station('a')], 0);
    for (var s = 0; s <= 120; s += 5) {
      backend.posC.add(Duration(seconds: s));
      await Future<void>.delayed(Duration.zero);
    }
    backend.stateC.add(BackendState.paused);
    await pumpEventQueue();
    expect(await db.select(db.plays).get(), isEmpty);
    expect((await db.select(db.tracks).get()).single.playCount, 0);
  });

  // The retry waits run on the test binding's fake clock; no row is read.
  CodecoreAudioHandler idleHandler() => CodecoreAudioHandler(
      backend, PlayQueue(), TrackRepository(db),
      onError: failures.add, online: online, onRadioStart: (s) => started.add(s.id));

  testWidgets('a station that does not open is tried again after 2, 5 and 15 s, then stops',
      (tester) async {
    final h = idleHandler();
    backend.failing.add('http://radio.test/a');
    await h.playStations([station('a')], 0);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(failures, isEmpty);
    await tester.pump(const Duration(milliseconds: 200)); // attempt 1 fails
    await tester.pump(const Duration(milliseconds: 4800));
    expect(failures, isEmpty);
    await tester.pump(const Duration(milliseconds: 300)); // attempt 2 fails
    await tester.pump(const Duration(milliseconds: 14700));
    expect(failures, isEmpty);
    await tester.pump(const Duration(milliseconds: 400)); // attempt 3 fails
    expect(failures.single.reason, PlaybackFailureReason.radioUnavailable);
    expect(failures.single.title, 'Radio a');
    expect(h.currentTrack, isNull);
    expect(started, ['a']); // retries are not new starts
  });

  testWidgets('a late drop of the station we are leaving does not retry it', (tester) async {
    final h = idleHandler();
    await h.playStations([station('a'), station('b')], 0);
    final switching = h.playStations([station('b')], 0);
    backend.stateC.add(BackendState.completed); // still the old stream's event
    await switching;
    await tester.pump(const Duration(seconds: 3));
    expect(backend.loadedUris.map((u) => u.uri.path), ['/a', '/b']);
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('a stream that drops while playing reconnects and plays again', (tester) async {
    final h = idleHandler();
    await h.playStations([station('a')], 0);
    expect(backend.loadedUris, hasLength(1));
    backend.stateC.add(BackendState.completed); // the server closed it
    await tester.pump(const Duration(milliseconds: 1900));
    expect(backend.loadedUris, hasLength(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(backend.loadedUris, hasLength(2));
    expect(backend.playing, isTrue);
    expect(failures, isEmpty);
    expect(started, ['a']);
    await tester.pump(const Duration(seconds: 11)); // the timer of a steady stream
  });

  test('resuming after a long pause connects again', () async {
    await handler.playStations([station('a')], 0);
    await handler.pause();
    now = now.add(const Duration(seconds: 31));
    await handler.play();
    expect(backend.loadedUris, hasLength(2));
    expect(started, ['a']);
    await handler.pause();
    now = now.add(const Duration(seconds: 5));
    await handler.play();
    expect(backend.loadedUris, hasLength(2));
  });

  test('a radio plays at 1x and the chosen rate returns with a track', () async {
    await handler.setSpeed(1.5);
    await handler.playStations([station('a')], 0);
    expect(backend.speed, 1.0);
    await handler.playQueue([libraryId], 0);
    expect(backend.speed, 1.5);
    expect(backend.loaded, ['/m/a.mp3']);
    expect(handler.isRadio, isFalse);
    expect(handler.playbackState.value.systemActions, contains(MediaAction.seek));
  });

  test('shuffle and repeat are set aside for the stations and come back', () async {
    await handler.setShuffleMode(AudioServiceShuffleMode.all);
    await handler.setRepeatMode(AudioServiceRepeatMode.all);
    await handler.playStations([station('a'), station('b')], 0);
    expect(handler.shuffleEnabled, isFalse);
    expect(handler.repeatMode, PlayRepeat.off);
    await handler.setShuffleMode(AudioServiceShuffleMode.all); // ignored
    expect(handler.shuffleEnabled, isFalse);
    await handler.playQueue([libraryId], 0);
    expect(handler.shuffleEnabled, isTrue);
    expect(handler.repeatMode, PlayRepeat.all);
  });

  test('library playback is unchanged: file load, play row, no radio hooks', () async {
    await handler.playQueue([libraryId], 0);
    expect(backend.loaded, ['/m/a.mp3']);
    expect(backend.loadedUris, isEmpty);
    expect(started, isEmpty);
    expect(handler.playbackState.value.speed, 1.0);
    for (var s = 0; s <= 40; s += 5) {
      backend.posC.add(Duration(seconds: s));
      await Future<void>.delayed(Duration.zero);
    }
    await pumpEventQueue();
    expect(await db.select(db.plays).get(), hasLength(1));
  });

  test('the same station keeps its id in the registry', () {
    final a = online.registerRadio(station('a'));
    expect(online.registerRadio(station('a')), a);
    expect(online.isRadioId(a), isTrue);
    expect(online.entryOf(a), isNull);
    expect(online.trackOf(a)!.path, 'online:radio:a');
    expect(online.trackOf(a)!.durationMs, 0);
  });
}
