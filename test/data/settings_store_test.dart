import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('playback state round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readPlayback().queueIds, isEmpty);
    await store.writePlayback(const SavedPlayback(
      queueIds: [3, 1, 2],
      index: 2,
      positionMs: 4500,
      volume: 0.5,
      shuffle: true,
      repeat: PlayRepeat.all,
    ));
    final s = store.readPlayback();
    expect(s.queueIds, [3, 1, 2]);
    expect(s.index, 2);
    expect(s.positionMs, 4500);
    expect(s.volume, 0.5);
    expect(s.shuffle, true);
    expect(s.repeat, PlayRepeat.all);
  });

  test('default theme is notte', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readSettings().theme, 'notte');
  });

  test('import thresholds default to 0.80 / 0.55 and round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readSettings().importSureThreshold, 0.80);
    expect(store.readSettings().importReviewThreshold, 0.55);
    await store.writeSettings(const AppSettings(
        importSureThreshold: 0.9, importReviewThreshold: 0.6));
    expect(store.readSettings().importSureThreshold, 0.9);
    expect(store.readSettings().importReviewThreshold, 0.6);
  });
}
