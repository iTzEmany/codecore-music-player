import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/database_providers.dart' show trackRepositoryProvider;
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/providers/library_providers.dart' show libraryQueriesProvider;
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/share_hub.dart';
import 'package:codecore/providers/share_providers.dart' show deviceNameProvider;
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/audio/playback_persistence.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:codecore/services/jam/speaker_jam.dart';
import 'package:codecore/services/share/discovery.dart' show Peer;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_backend.dart';

final _host = JamHost(deviceId: 'me', deviceName: 'PC');

class _Hub extends ShareHubNotifier {
  @override
  ShareHubState build() => const ShareHubState();
  @override
  JamHost? get jamHost => _host;
  @override
  String? get deviceId => 'me';
  @override
  Future<void> holdJam() async {}
  @override
  Future<void> releaseJam() async {}
}

void main() {
  late ProviderContainer c;
  late CodecoreAudioHandler handler;
  late FakeBackend backend;
  late List<int> ids;

  setUp(() async {
    _host.clearSession();
    SharedPreferences.setMockInitialValues({});
    final store = SettingsStore(await SharedPreferences.getInstance());
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
    c = ProviderContainer(overrides: [
      settingsStoreProvider.overrideWithValue(store),
      deviceNameProvider.overrideWithValue('Salotto'),
      shareHubProvider.overrideWith(_Hub.new),
      libraryQueriesProvider.overrideWithValue(LibraryQueries(db)),
      trackRepositoryProvider.overrideWithValue(TrackRepository(db)),
      audioHandlerProvider.overrideWithValue(handler),
      playbackPersistenceProvider.overrideWithValue(PlaybackPersistence(handler, store)),
      jamCacheDirProvider.overrideWith((ref) async => Directory.systemTemp.createTemp('jam_spk')),
      jamBackendFactoryProvider.overrideWithValue(FakeBackend.new),
    ]);
    addTearDown(c.dispose);
  });

  test('from idle it only waits: name announced, nothing else changes', () async {
    final jam = c.read(jamProvider.notifier);
    await jam.openSpeakerJam();
    expect(c.read(jamProvider).phase, JamPhase.idle);
    expect(_host.state, isNull);
    expect(c.read(shareHubProvider.notifier).speakerJamName, 'Salotto');
    final v = jam.speakerPort.view;
    expect((v.role, v.guests), (SpeakerRole.host, 0));

    await jam.closeSpeakerJamSilently();
    expect(c.read(shareHubProvider.notifier).speakerJamName, isNull);
    expect(jam.speakerPort.view.role, SpeakerRole.none);
  });

  test('a request accepted while waiting starts the speaker Jam', () async {
    final jam = c.read(jamProvider.notifier);
    await jam.openSpeakerJam();
    final r = _host.requests.putIfAbsent(
        'r1', () => JamRequest(id: 'r1', fromId: 'g', fromName: 'Phone', fromHost: '192.168.1.5', fromPort: 4000, token: 't', receivedAt: DateTime.now()));
    await jam.acceptRequest(r);
    final s = c.read(jamProvider).jam!;
    expect(c.read(jamProvider).isHost, isTrue);
    expect(s.speaker, isTrue);
    expect(s.outputs, ['me']);
  });

  test('a running host Jam becomes the speaker one', () async {
    final jam = c.read(jamProvider.notifier);
    _host.open();
    await jam.debugBegin(JamRole.host, _host.state!);
    await jam.openSpeakerJam();
    expect(_host.state!.speaker, isTrue);
    expect(c.read(shareHubProvider.notifier).speakerJamName, 'Salotto');
  });

  test('«Continua sul telefono»: the speaker coming back does not turn the Jam into the speaker one', () async {
    final jam = c.read(jamProvider.notifier);
    _host.open();
    await jam.debugBegin(JamRole.host, _host.state!);
    await jam.openSpeakerJam();
    await jam.send(const JamCommand.speakerAway());
    expect(await jam.continueOnPhone(), isNull);
    expect(_host.state!.speaker, isFalse);
    await jam.openSpeakerJam();
    expect(_host.state!.speaker, isFalse);
  });

  test('joining another Jam gives up the waiting speaker Jam', () async {
    final jam = c.read(jamProvider.notifier);
    await jam.openSpeakerJam();
    await jam.request(const Peer(id: 'x', name: 'X', host: '10.0.0.9', port: 1, platform: 'linux'));
    expect(c.read(shareHubProvider.notifier).speakerJamName, isNull);
    expect(jam.speakerPort.view.role, isNot(SpeakerRole.host));
  });

  test('the speaker port throws when the command is refused', () async {
    final jam = c.read(jamProvider.notifier);
    await expectLater(jam.speakerPort.send(const JamCommand.speakerAway()), throwsStateError);
  });

  test('a guest does nothing', () async {
    final jam = c.read(jamProvider.notifier);
    await jam.debugBegin(JamRole.guest, const JamState(version: 1, hostDeviceId: 'h', outputDeviceId: 'h'));
    await jam.openSpeakerJam();
    expect(_host.state, isNull);
  });

  JamRequest req() => _host.requests.putIfAbsent(
      'r2',
      () => JamRequest(
          id: 'r2',
          fromId: 'g',
          fromName: 'Phone',
          fromHost: '192.168.1.5',
          fromPort: 4000,
          token: 't',
          receivedAt: DateTime.now()));

  test('waiting and closing leave the playing queue untouched', () async {
    await handler.playQueue(ids, 1);
    final seeks = backend.seeks.length;
    final jam = c.read(jamProvider.notifier);
    void expectUntouched() {
      expect(handler.queueIds, ids);
      expect(handler.currentIndex, 1);
      expect(handler.isPlaying, isTrue);
      expect(backend.seeks.length, seeks);
    }

    await jam.openSpeakerJam();
    expectUntouched();
    await jam.closeSpeakerJamSilently();
    expectUntouched();
  });

  test('the Jam is seeded with the queue at the moment of the request', () async {
    await handler.playQueue(ids.take(2).toList(), 0);
    final jam = c.read(jamProvider.notifier);
    await jam.openSpeakerJam();
    await handler.playQueue(ids, 2);
    await jam.acceptRequest(req());
    final titles = [for (final i in c.read(jamProvider).jam!.items) i.title];
    expect(titles, ['Song 2', 'Song 3', 'Song 0', 'Song 1']);
  });
}
