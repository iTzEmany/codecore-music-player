import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_log.dart';

/// What the home-screen widget and the quick-settings tile show: the track
/// being played and whether it plays. Nothing about the position, so it only
/// changes when the track or the play state does.
class WidgetSnapshot {
  const WidgetSnapshot({
    this.title,
    this.artist,
    this.coverPath,
    this.playing = false,
  });

  /// Nothing loaded.
  static const empty = WidgetSnapshot();

  final String? title, artist, coverPath;
  final bool playing;

  @override
  bool operator ==(Object other) =>
      other is WidgetSnapshot &&
      other.title == title &&
      other.artist == artist &&
      other.coverPath == coverPath &&
      other.playing == playing;

  @override
  int get hashCode => Object.hash(title, artist, coverPath, playing);
}

/// Where the snapshot goes. Android writes it where the widget (Kotlin) reads
/// it; every other platform ignores it.
abstract class WidgetBridge {
  Future<void> update(WidgetSnapshot snapshot);

  /// The player is up and its queue restored: a widget tapped while the app
  /// was dead waits for this before it presses play again (the media button
  /// of a dead app is dropped by `audio_service`, see R63).
  Future<void> markReady();
}

class NoopWidgetBridge implements WidgetBridge {
  const NoopWidgetBridge();

  @override
  Future<void> update(WidgetSnapshot snapshot) async {}

  @override
  Future<void> markReady() async {}
}

/// Keys inside `FlutterSharedPreferences`. The file is read as
/// `flutter.<key>` by `NowPlayingWidget.kt` / `PlayTileService.kt`. A plain
/// preferences file works in every engine, also the one `audio_service`
/// starts without the activity, where a custom channel does not exist.
abstract final class WidgetKeys {
  static const title = 'widget.title';
  static const artist = 'widget.artist';
  static const cover = 'widget.cover';
  static const playing = 'widget.playing';

  /// Epoch ms of the last snapshot, always changing: it is what wakes the
  /// listener on the Kotlin side even when the rest is unchanged.
  static const stamp = 'widget.stamp';
  static const readyAt = 'widget.readyAt';
}

class PrefsWidgetBridge implements WidgetBridge {
  PrefsWidgetBridge(this._prefs, {int Function()? now})
      : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SharedPreferences _prefs;
  final int Function() _now;

  Future<void> _put(String key, String? value) =>
      value == null ? _prefs.remove(key) : _prefs.setString(key, value);

  @override
  Future<void> update(WidgetSnapshot s) async {
    try {
      await _put(WidgetKeys.title, s.title);
      await _put(WidgetKeys.artist, s.artist);
      await _put(WidgetKeys.cover, s.coverPath);
      await _prefs.setBool(WidgetKeys.playing, s.playing);
      // Last: the listener reads everything above when this changes.
      await _prefs.setInt(WidgetKeys.stamp, _now());
    } on Object catch (e, st) {
      AppLog.w('widget snapshot not saved', e, st);
    }
  }

  @override
  Future<void> markReady() async {
    try {
      await _prefs.setInt(WidgetKeys.readyAt, _now());
    } on Object catch (e, st) {
      AppLog.w('widget ready mark not saved', e, st);
    }
  }
}
