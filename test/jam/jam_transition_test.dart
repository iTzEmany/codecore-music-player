import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/crossfade_engine.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/audio/remote_transport.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_output.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';

/// Gapless and crossfade (phase 18) belong to the local player: the Jam keeps
/// its single backend and its own sync, whatever the transition setting is.
Future<void> settle() => pumpEventQueue();

class _Remote implements RemoteTransport {
  final calls = <String>[];
  @override
  RemoteStatus get status =>
      const RemoteStatus(title: 'Jam', playing: true, canSkip: true);
  @override
  Stream<RemoteStatus> get changes => const Stream.empty();
  @override
  Future<void> play() async => calls.add('play');
  @override
  Future<void> pause() async => calls.add('pause');
  @override
  Future<void> next() async => calls.add('next');
  @override
  Future<void> previous() async => calls.add('previous');
  @override
  Future<void> seek(Duration position) async => calls.add('seek');
}

void main() {
  test('the Jam output never prepares a next track, even on a backend that could', () async {
    final backend = FakeBackend();
    final out = JamOutput(
      deviceId: 'me',
      backend: backend,
      nowMs: () => 0,
      resolve: (i) async => JamSource.local('/music/${i.id}.mp3'),
    );
    const items = [
      JamItem(id: 1, ownerDeviceId: 'me', title: 'A', ext: 'mp3'),
      JamItem(id: 2, ownerDeviceId: 'me', title: 'B', ext: 'mp3'),
    ];
    JamState st(int cur) => JamState(
          version: cur + 1,
          items: items,
          currentIndex: cur,
          playing: true,
          positionMs: 0,
          positionAt: 0,
          hostDeviceId: 'host',
          outputDeviceId: 'me',
        );
    await out.apply(st(0));
    await out.apply(st(1));
    expect(backend.loaded, ['/music/1.mp3', '/music/2.mp3']);
    expect(backend.nextCalls, isEmpty);
    await out.dispose();
  });

  test('no Jam source mentions the gapless window or the crossfade engine', () {
    final files = Directory('lib/services/jam')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final f in files) {
      final text = f.readAsStringSync();
      for (final word in ['GaplessCapable', 'CrossfadeEngine', 'NextWindow', 'setNext(']) {
        expect(text.contains(word), isFalse, reason: '${f.path} uses $word');
      }
    }
  });

  // With remote controls attached the handler never reaches its window, so the
  // crossfade (the mode with the most local machinery) stands for gapless too.
  test('with the crossfade on, a Jam pauses the local player and then owns the controls', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final players = <FakeBackend>[];
    final handler = CodecoreAudioHandler(
      CrossfadeEngine(() {
        final f = FakeBackend();
        players.add(f);
        return f;
      }),
      PlayQueue(),
      TrackRepository(db),
      onError: (_) {},
    );
    addTearDown(handler.dispose);
    for (final n in ['a', 'b']) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/m/$n.mp3',
            title: n,
            albumKey: 'k',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
          ));
    }
    final ids = (await db.select(db.tracks).get()).map((t) => t.id).toList();
    await handler.playQueue(ids, 0);
    await handler.setTransition(TransitionMode.crossfade);
    await settle();
    expect(players[0].playing, isTrue);

    // What JamController._begin does:
    await handler.pause();
    expect(players[0].playing, isFalse);
    final remote = _Remote();
    handler.attachRemote(remote);
    final loads = players.fold<int>(0, (n, p) => n + p.loaded.length);
    final nexts = players.fold<int>(0, (n, p) => n + p.nextCalls.length);

    await handler.play();
    await handler.skipToNext();
    await settle();
    expect(remote.calls, ['play', 'next']);
    expect(players.fold<int>(0, (n, p) => n + p.loaded.length), loads);
    expect(players.fold<int>(0, (n, p) => n + p.nextCalls.length), nexts,
        reason: 'the local window is left alone while the Jam plays');
    expect(players[0].playing, isFalse);
  });
}
