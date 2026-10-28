import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/share_hub.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/audio/playback_persistence.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_backend.dart';

class _Jam extends JamController {
  @override
  JamUiState build() {
    super.build();
    return const JamUiState();
  }

  void setPhase(JamPhase p) => state = state.copyWith(phase: p);
}

class _Hub extends ShareHubNotifier {
  @override
  ShareHubState build() => const ShareHubState();
}

void main() {
  late FakeBackend backend;
  late CodecoreAudioHandler handler;
  late SettingsStore store;
  late ProviderContainer c;
  late List<int> ids;
  var cacheFails = false;

  setUp(() async {
    cacheFails = false;
    SharedPreferences.setMockInitialValues({});
    store = SettingsStore(await SharedPreferences.getInstance());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    backend = FakeBackend();
    handler = CodecoreAudioHandler(
        backend, PlayQueue(), TrackRepository(db), onError: (_) {});
    addTearDown(handler.dispose);
    ids = [
      for (var i = 0; i < 4; i++)
        await db.into(db.tracks).insert(TracksCompanion.insert(
              path: '/m/t$i.mp3',
              title: 'Song $i',
              albumKey: 'k',
              format: 'mp3',
              sizeBytes: 1,
              mtimeMs: 1,
              addedAt: i,
            )),
    ];
    final persistence = PlaybackPersistence(handler, store);
    c = ProviderContainer(overrides: [
      settingsStoreProvider.overrideWithValue(store),
      shareHubProvider.overrideWith(_Hub.new),
      jamProvider.overrideWith(_Jam.new),
      audioHandlerProvider.overrideWithValue(handler),
      playbackPersistenceProvider.overrideWithValue(persistence),
      jamCacheDirProvider.overrideWith((ref) async {
        if (cacheFails) throw StateError('no cache dir');
        return Directory.systemTemp.createTemp('jam_restore');
      }),
      jamBackendFactoryProvider.overrideWithValue(FakeBackend.new),
    ]);
    addTearDown(c.dispose);
    // Restored paused, as at app start: the position stream stays silent.
    await handler.restore(ids.take(3).toList(), 1, const Duration(minutes: 1));
    await persistence.flush();
    c.read(jamProvider);
  });

  const jamState = JamState(
      version: 1, hostDeviceId: 'h', outputDeviceId: 'h');

  Future<void> enterAndChange([JamRole role = JamRole.guest]) async {
    await c.read(jamProvider.notifier).debugBegin(role, jamState);
    // The Jam (or the app, meanwhile) leaves another queue behind.
    await handler.playQueue([ids[3]], 0);
    // Whatever the disk holds now differs from the restored queue.
    await store.writePlayback(SavedPlayback(queueIds: [ids[3]], positionMs: 5000));
    backend.seeks.clear();
  }

  void expectBack() {
    expect(handler.queueIds, ids.take(3));
    expect(handler.currentIndex, 1);
    expect(handler.isPlaying, false);
    expect(backend.seeks.last, const Duration(minutes: 1));
    expect(store.readPlayback().queueIds, ids.take(3));
    expect(store.readPlayback().index, 1);
    expect(store.readPlayback().positionMs, 60000);
  }

  test('the guest leaves: same queue, track and position, paused', () async {
    await enterAndChange();
    await c.read(jamProvider.notifier).end();
    expectBack();
    // The disk follows the player again.
    await handler.playQueue([ids[3]], 0);
    await c.read(playbackPersistenceProvider)!.flush();
    expect(store.readPlayback().queueIds, [ids[3]]);
  });

  test('a Jam that cannot start gives the queue and the disk back', () async {
    cacheFails = true;
    await handler.playQueue([ids[3]], 0);
    await store.writePlayback(SavedPlayback(queueIds: [ids[3]]));
    await handler.restore(ids.take(3).toList(), 1, const Duration(minutes: 1));
    backend.seeks.clear();
    await expectLater(
        c.read(jamProvider.notifier).debugBegin(JamRole.guest, jamState),
        throwsStateError);
    expectBack();
    await handler.playQueue([ids[3]], 0);
    await c.read(playbackPersistenceProvider)!.flush();
    expect(store.readPlayback().queueIds, [ids[3]]);
  });

  test('lost while the guest queue is being saved: the Jam never starts', () async {
    final jam = c.read(jamProvider.notifier) as _Jam;
    jam.setPhase(JamPhase.requesting);
    await Future.wait([
      jam.debugBegin(JamRole.guest, jamState),
      jam.debugFinish(lost: true),
    ]);
    expect(c.read(jamProvider).phase, JamPhase.ended);
    expect(handler.queueIds, ids.take(3));
    expect(handler.isPlaying, false);
  });

  test('the host ends the Jam, or the Jam is lost: same queue back, paused', () async {
    await enterAndChange();
    await c.read(jamProvider.notifier).debugFinish(lost: true);
    expect(c.read(jamProvider).lost, true);
    expectBack();
  });

  test('a host keeps its own queue untouched and the disk free', () async {
    await c.read(jamProvider.notifier).debugBegin(JamRole.host, jamState);
    await handler.playQueue([ids[3]], 0);
    await c.read(jamProvider.notifier).debugFinish();
    expect(handler.queueIds, [ids[3]]);
    expect(store.readPlayback().queueIds, ids.take(3));
    await c.read(playbackPersistenceProvider)!.flush();
    expect(store.readPlayback().queueIds, [ids[3]]);
  });

  test('a restart mid-Jam finds the queue from before the Jam', () async {
    await c.read(jamProvider.notifier).debugBegin(JamRole.guest, jamState);
    await handler.playQueue([ids[3]], 0);
    await c.read(playbackPersistenceProvider)!.flush();
    final saved = store.readPlayback();
    expect(saved.queueIds, ids.take(3));
    expect(saved.index, 1);
    expect(saved.positionMs, 60000);
  });
}
