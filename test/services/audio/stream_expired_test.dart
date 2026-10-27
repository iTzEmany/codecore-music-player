import 'dart:async';
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/just_audio_backend.dart';
import 'package:codecore/services/audio/online_entries.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/stream/stream_preparer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import '../../support/fake_backend.dart';
import '../../support/fake_stream_preparer.dart';

void main() {
  test('a refused stream is told by the status or by ExoPlayer\'s «Source error»', () {
    expect(streamLooksExpired(Exception('Response code: 403')), isTrue);
    expect(streamLooksExpired(Exception('status 410 Gone')), isTrue);
    expect(streamLooksExpired(PlayerException(0, 'Source error', null)), isTrue);
    expect(streamLooksExpired(PlayerException(1, 'Renderer error', null)), isFalse);
    expect(streamLooksExpired(Exception('boom')), isFalse);
  });

  group('an address that fails while playing (R-76)', () {
    final first = Uri.parse('https://rr1.googlevideo.com/first');
    final second = Uri.parse('https://rr2.googlevideo.com/second');
    const pos = Duration(seconds: 42);
    late AppDatabase db;
    late FakeBackend backend;
    late FakeStreamPreparer preparer;
    late OnlineEntries online;
    late CodecoreAudioHandler handler;
    late Directory dir;
    late List<PlaybackFailure> failures;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      backend = FakeBackend();
      failures = [];
      dir = Directory.systemTemp.createTempSync('stream_expired');
      preparer = FakeStreamPreparer(TrackRepository(db), dir);
      online = OnlineEntries();
      handler = CodecoreAudioHandler(backend, PlayQueue(), TrackRepository(db),
          onError: failures.add, online: online, preparer: preparer);
      preparer.urls['youtube:v1'] = (first, const {});
      final id = online.register(YtResult(
          id: 'v1', title: 'Song', channel: 'C', artists: const ['A'], album: 'B',
          duration: const Duration(minutes: 3)));
      await handler.playQueue([id], 0);
      backend.stateC.add(BackendState.playing);
      backend.posC.add(pos);
      await pumpEventQueue();
      expect(backend.loadedUris.single.uri, first);
    });
    tearDown(() async {
      await handler.dispose();
      await db.close();
      dir.deleteSync(recursive: true);
    });

    void fail() => backend.stateC.add(BackendState.error);

    test('the file is there: it loads and goes on from the same place', () async {
      fail();
      await pumpEventQueue();
      expect(preparer.restarted, ['youtube:v1']);
      expect(backend.loaded.single, endsWith('youtube_v1.m4a'));
      expect(backend.seeks.last, pos);
      expect(backend.playing, isTrue);
      expect(failures, isEmpty);
    });

    test('a fresh address: loadUri and seek, no file', () async {
      preparer.restarts['youtube:v1'] = [StreamStart.url(second, const {})];
      fail();
      await pumpEventQueue();
      expect(backend.loadedUris.last.uri, second);
      expect(backend.loaded, isEmpty);
      expect(backend.seeks.last, pos);
    });

    test('the fresh address fails too: the file, from the same place', () async {
      preparer.restarts['youtube:v1'] = [StreamStart.url(second, const {})];
      backend.expiring.add(second.toString());
      fail();
      await pumpEventQueue();
      expect(backend.loaded.single, endsWith('youtube_v1.m4a'));
      expect(backend.seeks.last, pos);
      expect(failures, isEmpty);
    });

    test('a pause while it recovers: it ends paused', () async {
      final gate = preparer.gates['youtube:v1'] = Completer<void>();
      fail();
      await pumpEventQueue();
      await handler.pause();
      gate.complete();
      await pumpEventQueue();
      expect(backend.loaded.single, endsWith('youtube_v1.m4a'));
      expect(backend.playing, isFalse);
    });

    test('an offline restart tells the network is unavailable', () async {
      preparer.failing.add('youtube:v1');
      preparer.failure = const YtException(YtErrorKind.network, 'down');
      fail();
      await pumpEventQueue();
      expect(failures.first.reason, PlaybackFailureReason.networkUnavailable);
    });

    test('a skip during the recovery: the old address is not loaded over the new track', () async {
      final gate = preparer.restartGate = Completer<void>();
      preparer.restarts['youtube:v1'] = [StreamStart.url(second, const {})];
      fail();
      await pumpEventQueue();
      await handler.playQueue([online.register(YtResult(
          id: 'v2', title: 'Two', channel: 'C', artists: const ['A'], album: 'B',
          duration: const Duration(minutes: 3)))], 0);
      gate.complete();
      await pumpEventQueue();
      expect(backend.loadedUris.map((u) => u.uri), [first]);
    });

    test('an error during the restart does not start another one; nor does play', () async {
      final gate = preparer.restartGate = Completer<void>();
      fail();
      await pumpEventQueue();
      fail();
      await handler.play();
      await pumpEventQueue();
      expect(preparer.restarted, ['youtube:v1']);
      gate.complete();
      await pumpEventQueue();
      expect(preparer.restarted, ['youtube:v1']);
    });

    test('three errors in a row: two restarts, then the file', () async {
      preparer.restarts['youtube:v1'] = [StreamStart.url(second, const {}), StreamStart.url(second, const {})];
      for (var i = 0; i < 3; i++) {
        fail();
        await pumpEventQueue();
      }
      expect(preparer.restarted.length, 2);
      expect(backend.loaded.single, endsWith('youtube_v1.m4a'));
    });

    test('paused: nothing happens until play', () async {
      await handler.pause();
      fail();
      await pumpEventQueue();
      expect(preparer.restarted, isEmpty);
      await handler.play();
      await pumpEventQueue();
      expect(preparer.restarted, ['youtube:v1']);
      expect(backend.loaded.single, endsWith('youtube_v1.m4a'));
      expect(backend.seeks.last, pos);
    });
  });
}
