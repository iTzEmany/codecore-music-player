import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/services/audio/audio_backend.dart' show TransitionMode;
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/services/online/youtube_service.dart'
    show DownloadFormat, SearchSource;
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

  test('playback speed defaults to 1× and is kept within 0.5–2', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readSettings().playbackSpeed, 1.0);
    await store.writeSettings(const AppSettings(playbackSpeed: 1.5));
    expect(store.readSettings().playbackSpeed, 1.5);
    SharedPreferences.setMockInitialValues({'playbackSpeed': 7.0});
    expect((await SettingsStore.open()).readSettings().playbackSpeed, 2.0);
  });

  test('the track transition defaults to normal, with a 6 s crossfade kept within 2–12', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    var s = store.readSettings();
    expect(s.transition, TransitionMode.normal);
    expect(s.crossfadeSeconds, 6);
    expect(s.crossfadePlainInAlbum, isTrue);
    await store.writeSettings(const AppSettings(
        transition: TransitionMode.crossfade,
        crossfadeSeconds: 9,
        crossfadePlainInAlbum: false));
    s = store.readSettings();
    expect(s.transition, TransitionMode.crossfade);
    expect(s.crossfadeSeconds, 9);
    expect(s.crossfadePlainInAlbum, isFalse);
    SharedPreferences.setMockInitialValues({'crossfadeSeconds': 99, 'transition': 'gapless'});
    s = (await SettingsStore.open()).readSettings();
    expect(s.crossfadeSeconds, 12);
    expect(s.transition, TransitionMode.gapless);
    SharedPreferences.setMockInitialValues({'transition': 'something-old'});
    expect((await SettingsStore.open()).readSettings().transition, TransitionMode.normal);
  });

  test('theme notte and accent violet by default; the light theme name is kept', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readSettings().theme, 'notte');
    expect(store.readSettings().accent, 'viola');
    await store.writeSettings(const AppSettings(theme: 'chiaro', accent: 'rosa'));
    final s = store.readSettings();
    expect(s.theme, 'chiaro');
    expect(s.accent, 'rosa');
  });

  test('the listening history is on by default and the choice is kept', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readSettings().recordHistory, isTrue);
    await store.writeSettings(const AppSettings(recordHistory: false));
    expect(store.readSettings().recordHistory, isFalse);
  });

  test('online sources: YouTube and no SoundCloud fallback by default; both are remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readSettings().searchSource, SearchSource.youtube);
    expect(store.readSettings().importSoundCloud, isFalse);

    await store.writeSettings(store.readSettings().copyWith(
        searchSource: SearchSource.soundcloud, importSoundCloud: true));
    final again = store.readSettings();
    expect(again.searchSource, SearchSource.soundcloud);
    expect(again.importSoundCloud, isTrue);
  });

  test('an unknown stored source falls back to YouTube', () async {
    SharedPreferences.setMockInitialValues({'searchSource': 'bandcamp'});
    final store = await SettingsStore.open();
    expect(store.readSettings().searchSource, SearchSource.youtube);
  });

  test('downloads are M4A by default, also for those who had the old MP3 default; a choice is remembered',
      () async {
    SharedPreferences.setMockInitialValues({'downloadOriginal': false});
    final store = await SettingsStore.open();
    expect(store.readSettings().downloadFormat, DownloadFormat.m4a);

    await store.writeSettings(
        store.readSettings().copyWith(downloadFormat: DownloadFormat.mp3High));
    expect(store.readSettings().downloadFormat, DownloadFormat.mp3High);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('downloadOriginal'), isFalse, reason: 'the old switch is gone');
  });

  test('the groups the user said are not duplicates are remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readNotDuplicates(), isEmpty);
    await store.writeNotDuplicates({'3,4', '1,2'});
    expect(store.readNotDuplicates(), {'1,2', '3,4'});
  });

  test('Shuffle+ is off, one in 4, Wi‑Fi only by default; its choices are saved and kept within 3–10', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    var s = store.readSettings();
    expect(s.shufflePlus, isFalse);
    expect(s.shufflePlusEvery, 4);
    expect(s.shufflePlusUnmeteredOnly, isTrue);
    await store.writeSettings(
        s.copyWith(shufflePlus: true, shufflePlusEvery: 7, shufflePlusUnmeteredOnly: false));
    s = store.readSettings();
    expect(s.shufflePlus, isTrue);
    expect(s.shufflePlusEvery, 7);
    expect(s.shufflePlusUnmeteredOnly, isFalse);

    SharedPreferences.setMockInitialValues({'shufflePlusEvery': 99});
    expect((await SettingsStore.open()).readSettings().shufflePlusEvery, 10);
  });
}
