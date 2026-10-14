import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/sleep_timer_provider.dart';
import 'package:codecore/providers/settings_providers.dart';
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
}
