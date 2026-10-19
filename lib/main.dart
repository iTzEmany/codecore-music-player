import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'core/paths.dart';
import 'core/platform.dart';
import 'data/db/app_database.dart';
import 'data/repositories/library_queries.dart';
import 'data/repositories/play_history_repository.dart';
import 'data/repositories/playlist_repository.dart';
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
import 'services/audio/media_browse_tree.dart';
import 'services/audio/play_queue.dart';
import 'services/audio/playback_persistence.dart';
import 'services/android/widget_bridge.dart';
import 'services/android/widget_sync.dart';
import 'services/backup/restore_service.dart';
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

  // A restore chosen in the last run replaces the database before it is opened.
  try {
    await applyPendingRestore(
      dbFile: await databaseFile(),
      staging: await restoreStagingDir(),
      prefs: await SharedPreferences.getInstance(),
      coversDir: Directory(await coversDir()),
      schemaVersion: kSchemaVersion,
    );
  } on Object catch (e, st) {
    AppLog.e('pending restore could not run', e, st);
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

  handler.browse = MediaBrowseTree(
    DbBrowseSource(TrackRepository(db), LibraryQueries(db), PlaylistRepository(db)),
    labels: BrowseLabels.forLanguage(settingsStore.readSettings().language),
    coverUri: (k) => covers.fileFor(k)?.uri,
  );
  // Home-screen widget and quick tile (Android): fed from here, not from the
  // UI, because the player outlives the activity.
  if (Platform.isAndroid) {
    final bridge = PrefsWidgetBridge(await SharedPreferences.getInstance());
    WidgetSync(
      tracks: handler.currentTrackStream,
      playing: handler.playbackState.map((s) => s.playing).distinct(),
      bridge: bridge,
      coverPath: (t) => t.coverKey == null ? null : covers.fileFor(t.coverKey!)?.path,
      initialTrack: handler.currentTrack,
      initialPlaying: handler.playbackState.value.playing,
    );
    await bridge.markReady();
  }

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
