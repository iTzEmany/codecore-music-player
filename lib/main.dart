import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'core/paths.dart';
import 'core/platform.dart';
import 'data/db/app_database.dart';
import 'data/repositories/play_history_repository.dart';
import 'data/repositories/podcast_repository.dart';
import 'data/repositories/track_repository.dart';
import 'data/settings/settings_store.dart';
import 'providers/database_providers.dart';
import 'providers/library_providers.dart';
import 'providers/player_providers.dart';
import 'providers/settings_providers.dart';
import 'providers/share_providers.dart';
import 'services/audio/codecore_audio_handler.dart';
import 'services/audio/crossfade_engine.dart';
import 'services/audio/just_audio_backend.dart';
import 'services/audio/play_queue.dart';
import 'services/audio/playback_persistence.dart';
import 'services/covers/cover_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.i('avvio');
  LicenseRegistry.addLicense(() async* {
    for (final f in const ['Figtree', 'Unbounded']) {
      yield LicenseEntryWithLineBreaks(
          [f], await rootBundle.loadString('assets/fonts/OFL-$f.txt'));
    }
  });
  if (Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized();
  }

  final db = AppDatabase.production();
  final tracks = TrackRepository(db);
  final covers = CoverStore(Directory(await coversDir()));
  final errors = StreamController<PlaybackFailure>.broadcast();
  CodecoreAudioHandler build() => CodecoreAudioHandler(
        CrossfadeEngine(() => JustAudioBackend(withEqualizer: true)),
        PlayQueue(),
        tracks,
        onError: errors.add,
        history: PlayHistoryRepository(db),
        onEpisodeHeard: (id) => unawaited(PodcastRepository(db)
            .markPlayedByTrack(id, true, now: DateTime.now().millisecondsSinceEpoch)),
        coverPathFor: (t) =>
            t.coverKey == null ? null : covers.fileFor(t.coverKey!)?.path,
      );

  final CodecoreAudioHandler handler;
  if (isAndroid) {
    handler = await AudioService.init<CodecoreAudioHandler>(
      builder: build,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.codecore.player.audio',
        androidNotificationChannelName: 'Riproduzione',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } else {
    handler = build();
  }

  final settingsStore = await SettingsStore.open();
  final persistence = PlaybackPersistence(handler, settingsStore);
  try {
    await persistence.restore();
  } on Object catch (e, st) {
    AppLog.w('restore playback failed', e, st);
  }
  persistence.start();

  var systemName = Platform.localHostname;
  if (Platform.isAndroid) {
    try {
      systemName = await const MethodChannel('codecore/share')
              .invokeMethod<String>('deviceName') ??
          systemName;
    } on Object catch (e) {
      AppLog.d('device name lookup failed', e);
    }
  }

  runApp(ProviderScope(
    overrides: [
      systemDeviceNameProvider.overrideWithValue(systemName),
      databaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(settingsStore),
      audioHandlerProvider.overrideWithValue(handler),
      playbackPersistenceProvider.overrideWithValue(persistence),
      playerErrorsProvider.overrideWithValue(errors.stream),
      coversDirProvider.overrideWithValue(covers.dir),
    ],
    child: const CodecoreApp(),
  ));
}
