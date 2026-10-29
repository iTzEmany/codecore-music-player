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

  setUp(() async {
    _host.clearSession();
    SharedPreferences.setMockInitialValues({});
    final store = SettingsStore(await SharedPreferences.getInstance());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final handler = CodecoreAudioHandler(
        FakeBackend(), PlayQueue(), TrackRepository(db), onError: (_) {});
    addTearDown(handler.dispose);
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

  test('from idle: host of a speaker Jam, host the only output, name announced', () async {
    final jam = c.read(jamProvider.notifier);
    await jam.openSpeakerJam();
    final s = c.read(jamProvider).jam!;
    expect(c.read(jamProvider).isHost, isTrue);
    expect(s.speaker, isTrue);
    expect(s.outputs, ['me']);
    expect(c.read(shareHubProvider.notifier).speakerJamName, 'Salotto');

    await jam.closeSpeakerJamSilently();
    expect(c.read(jamProvider).phase, JamPhase.idle);
    expect(c.read(shareHubProvider.notifier).speakerJamName, isNull);
  });

  test('a running host Jam becomes the speaker one', () async {
    final jam = c.read(jamProvider.notifier);
    _host.open();
    await jam.debugBegin(JamRole.host, _host.state!);
    await jam.openSpeakerJam();
    expect(_host.state!.speaker, isTrue);
    expect(c.read(shareHubProvider.notifier).speakerJamName, 'Salotto');
  });

  test('a guest does nothing', () async {
    final jam = c.read(jamProvider.notifier);
    await jam.debugBegin(JamRole.guest, const JamState(version: 1, hostDeviceId: 'h', outputDeviceId: 'h'));
    await jam.openSpeakerJam();
    expect(_host.state, isNull);
  });
}
