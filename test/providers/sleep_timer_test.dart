import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/sleep_timer_provider.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codecore/data/settings/settings_store.dart';

import '../support/fake_backend.dart';

void main() {
  test('timer states', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final handler = CodecoreAudioHandler(
        FakeBackend(), PlayQueue(), TrackRepository(db),
        onError: (_) {});
    final c = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      settingsStoreProvider
          .overrideWithValue(await SettingsStore.open()),
    ]);
    addTearDown(c.dispose);
    final n = c.read(sleepTimerProvider.notifier);

    n.startAtTrackEnd();
    expect(c.read(sleepTimerProvider).atTrackEnd, true);
    expect(handler.pauseAtTrackEnd, true);

    n.startMinutes(30);
    expect(c.read(sleepTimerProvider).endsAt, isNotNull);
    expect(handler.pauseAtTrackEnd, false);

    n.cancel();
    expect(c.read(sleepTimerProvider).active, false);
  });

  test('«end of track» clears once the handler has stopped at it', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = TrackRepository(db);
    final id = await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/a.mp3',
          title: 'a',
          albumKey: 'k',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
        ));
    final backend = FakeBackend();
    final handler = CodecoreAudioHandler(backend, PlayQueue(), repo,
        onError: (_) {});
    addTearDown(handler.dispose);
    final c = ProviderContainer(overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      settingsStoreProvider.overrideWithValue(await SettingsStore.open()),
    ]);
    addTearDown(c.dispose);
    c.read(sleepTimerProvider); // alive, listening
    await handler.playQueue([id], 0);
    c.read(sleepTimerProvider.notifier).startAtTrackEnd();
    expect(c.read(sleepTimerProvider).active, true);

    backend.stateC.add(BackendState.completed);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(c.read(sleepTimerProvider).active, false);
    expect(handler.pauseAtTrackEnd, false);
  });
}
