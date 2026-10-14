import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'core/paths.dart';
import 'core/platform.dart';
import 'data/db/app_database.dart';
import 'data/repositories/track_repository.dart';
import 'data/settings/settings_store.dart';
import 'providers/database_providers.dart';
import 'providers/library_providers.dart';
import 'providers/player_providers.dart';
import 'services/audio/codecore_audio_handler.dart';
import 'services/audio/just_audio_backend.dart';
import 'services/audio/play_queue.dart';
import 'services/audio/playback_persistence.dart';
import 'services/covers/cover_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.i('avvio');
  if (Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized();
  }

  final db = AppDatabase.production();
  final tracks = TrackRepository(db);
  final covers = CoverStore(Directory(await coversDir()));
  final errors = StreamController<String>.broadcast();
  CodecoreAudioHandler build() => CodecoreAudioHandler(
        JustAudioBackend(),
        PlayQueue(),
        tracks,
        onError: errors.add,
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

  final persistence =
      PlaybackPersistence(handler, await SettingsStore.open());
  try {
    await persistence.restore();
  } on Object catch (e, st) {
    AppLog.w('restore playback failed', e, st);
  }
  persistence.start();

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      audioHandlerProvider.overrideWithValue(handler),
      playbackPersistenceProvider.overrideWithValue(persistence),
      playerErrorsProvider.overrideWithValue(errors.stream),
      coversDirProvider.overrideWith((ref) async => covers.dir),
    ],
    child: const CodecoreApp(),
  ));
}
