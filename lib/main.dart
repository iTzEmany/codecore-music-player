import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show DeviceOrientation, MethodChannel, SystemChrome, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'core/memory_budget.dart';
import 'core/paths.dart';
import 'core/platform.dart';
import 'data/db/app_database.dart';
import 'data/repositories/library_queries.dart';
import 'data/repositories/play_history_repository.dart';
import 'data/repositories/playlist_repository.dart';
import 'data/repositories/podcast_repository.dart';
import 'data/repositories/radio_repository.dart';
import 'services/radio/radio_browser_client.dart';
import 'data/repositories/track_repository.dart';
import 'data/settings/settings_store.dart';
import 'providers/database_providers.dart';
import 'providers/youtube_providers.dart' show createYtDlpService, ytDlpServiceProvider;
import 'providers/library_providers.dart';
import 'providers/player_providers.dart';
import 'providers/radio_providers.dart' show radioClientProvider;
import 'providers/settings_providers.dart';
import 'providers/share_providers.dart';
import 'services/audio/codecore_audio_handler.dart';
import 'services/audio/crossfade_engine.dart';
import 'services/audio/just_audio_backend.dart';
import 'services/audio/media_browse_tree.dart';
import 'services/audio/online_entries.dart';
import 'providers/listen_providers.dart' show fastClientGateProvider;
import 'services/audio/stream_address_cache.dart';
import 'services/online/youtube_service.dart' show StreamSource, FastClientGate;
import 'services/audio/mpris_controls.dart';
import 'services/audio/smtc_controls.dart';
import 'services/audio/play_queue.dart';
import 'services/audio/playback_persistence.dart';
import 'services/android/widget_bridge.dart';
import 'services/android/widget_sync.dart';
import 'services/backup/restore_service.dart';
import 'services/covers/cover_store.dart';
import 'services/covers/cover_thumbnails.dart';
import 'services/perf/perf_probe.dart';

Future<void> main() async {
  final sinceMain = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.i('avvio');
  // A phone stays upright however it is turned; desktops are not touched.
  // Not waited for: the manifest already says portrait, and the answer comes
  // slowly while Android is still building the activity (~250 ms on a Mi A3).
  if (Platform.isAndroid) {
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]));
  }
  LicenseRegistry.addLicense(() async* {
    for (final f in const ['Figtree', 'Unbounded']) {
      yield LicenseEntryWithLineBreaks(
          [f], await rootBundle.loadString('assets/fonts/OFL-$f.txt'));
    }
  });
  if (Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized();
  }

  if (kPerfBuild) PerfProbe.mark('binding', sinceMain);
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

  if (kPerfBuild) PerfProbe.mark('pendingRestore', sinceMain);
  final db = AppDatabase.production();
  final tracks = TrackRepository(db);
  final covers = CoverStore(Directory(await coversDir()), thumbnails: encodeCoverThumbnail);
  if (Platform.isAndroid) {
    unawaited(() async {
      try {
        final total = memTotalKb(await File('/proc/meminfo').readAsString());
        PaintingBinding.instance.imageCache.maximumSizeBytes = imageCacheBytes(total);
      } on FileSystemException catch (e) {
        AppLog.d('meminfo unreadable', e);
      }
    }());
  }
  final errors = StreamController<PlaybackFailure>.broadcast();
  // The one yt-dlp service of the app: the UI (through the provider) and the
  // player (direct addresses of online entries) share it.
  final ytDlp = createYtDlpService();
  final onlineEntries = OnlineEntries();
  final fastGate = FastClientGate();
  final addresses = StreamAddressCache(
      (r, {required fast}) => (ytDlp as StreamSource).streamUrl(r, fast: fast),
      gate: fastGate);
  // Shared with the Radio page, so the chosen server is remembered once.
  final radioClient = RadioBrowserClient.standard();
  final radioRepo = RadioRepository(db);
  CodecoreAudioHandler build() => CodecoreAudioHandler(
        CrossfadeEngine(() => JustAudioBackend(withEqualizer: true)),
        PlayQueue(),
        tracks,
        onError: errors.add,
        online: onlineEntries,
        addresses: addresses,
        onRadioStart: (station) {
          // The courtesy click for Radio Browser's own stations only.
          if (!station.id.startsWith('manual:')) {
            unawaited(radioClient.click(station.id).catchError((Object e, StackTrace st) {
              AppLog.w('radio click failed', e, st);
            }));
          }
          unawaited(radioRepo.touchPlayed(station.id).catchError((Object e, StackTrace st) {
            AppLog.w('radio last-played failed', e, st);
          }));
        },
        history: PlayHistoryRepository(db),
        onEpisodeHeard: (id) => unawaited(PodcastRepository(db)
            .markPlayedByTrack(id, true, now: DateTime.now().millisecondsSinceEpoch)),
        coverPathFor: (t) =>
            t.coverKey == null ? null : covers.fileFor(t.coverKey!)?.path,
      );

  if (kPerfBuild) PerfProbe.mark('covers', sinceMain);
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

  if (kPerfBuild) PerfProbe.mark('audioService', sinceMain);
  // Linux: the track and the media keys in the desktop (MPRIS). A failure is
  // logged and the app runs without.
  if (Platform.isLinux) unawaited(MprisControls().attach(handler));
  // Windows: the same through SMTC.
  if (Platform.isWindows) unawaited(SmtcControls().attach(handler));

  if (kPerfBuild) PerfProbe.mark('platformControls', sinceMain);
  final settingsStore = await SettingsStore.open();
  if (kPerfBuild) await PerfProbe.prepareSettings(settingsStore);
  final persistence = PlaybackPersistence(handler, settingsStore);

  if (kPerfBuild) PerfProbe.mark('settings', sinceMain);
  handler.browse = MediaBrowseTree(
    DbBrowseSource(TrackRepository(db), LibraryQueries(db), PlaylistRepository(db), radioRepo),
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

  if (kPerfBuild) PerfProbe.mark('widget', sinceMain);
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

  if (kPerfBuild) PerfProbe.mark('deviceName', sinceMain);
  runApp(ProviderScope(
    overrides: [
      systemDeviceNameProvider.overrideWithValue(systemName),
      databaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(settingsStore),
      audioHandlerProvider.overrideWithValue(handler),
      radioClientProvider.overrideWithValue(radioClient),
      ytDlpServiceProvider.overrideWithValue(ytDlp),
      fastClientGateProvider.overrideWithValue(fastGate),
      playbackPersistenceProvider.overrideWithValue(persistence),
      playerErrorsProvider.overrideWithValue(errors.stream),
      coversDirProvider.overrideWithValue(covers.dir),
    ],
    child: const CodecoreApp(),
  ));
  // The last queue comes back right after the first frame, not before it:
  // preparing the current song in the player is not needed to draw the app.
  unawaited(() async {
    try {
      await persistence.restore();
    } on Object catch (e, st) {
      AppLog.w('restore playback failed', e, st);
    }
    persistence.start();
  }());
  if (kPerfBuild) {
    unawaited(PerfProbe.start(db: db, covers: covers, sinceMain: sinceMain));
  }
  // Thumbnails of the covers saved before there were any: after start-up.
  unawaited(WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    await covers.fillMissingThumbnails();
  }));
}
