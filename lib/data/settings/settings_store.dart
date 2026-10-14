import 'package:shared_preferences/shared_preferences.dart';

import '../../services/audio/play_queue.dart';

class AppSettings {
  const AppSettings({
    this.theme = 'oled',
    this.fontScale = 1.0,
    this.compactMode = false,
    this.reducedMotion = false,
    this.language = 'it',
    this.autoEnrich = false,
    this.autoLyrics = false,
    this.showUndoSnackbar = true,
    this.deviceName,
  });

  final String theme;
  final double fontScale;
  final bool compactMode, reducedMotion, autoEnrich, autoLyrics, showUndoSnackbar;
  final String language;

  /// Shown to the device on the other side of a LAN share; null = hostname.
  final String? deviceName;

  AppSettings copyWith({
    String? theme,
    double? fontScale,
    bool? compactMode,
    bool? reducedMotion,
    String? language,
    bool? autoEnrich,
    bool? autoLyrics,
    bool? showUndoSnackbar,
    String? deviceName,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        fontScale: fontScale ?? this.fontScale,
        compactMode: compactMode ?? this.compactMode,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        language: language ?? this.language,
        autoEnrich: autoEnrich ?? this.autoEnrich,
        autoLyrics: autoLyrics ?? this.autoLyrics,
        showUndoSnackbar: showUndoSnackbar ?? this.showUndoSnackbar,
        deviceName: deviceName ?? this.deviceName,
      );
}

class SavedPlayback {
  const SavedPlayback({
    this.queueIds = const [],
    this.index = 0,
    this.positionMs = 0,
    this.volume = 1.0,
    this.shuffle = false,
    this.repeat = PlayRepeat.off,
  });

  final List<int> queueIds;
  final int index, positionMs;
  final double volume;
  final bool shuffle;
  final PlayRepeat repeat;
}

class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  AppSettings readSettings() => AppSettings(
        theme: _prefs.getString('theme') ?? 'oled',
        fontScale: _prefs.getDouble('fontScale') ?? 1.0,
        compactMode: _prefs.getBool('compactMode') ?? false,
        reducedMotion: _prefs.getBool('reducedMotion') ?? false,
        language: _prefs.getString('language') ?? 'it',
        autoEnrich: _prefs.getBool('autoEnrich') ?? false,
        autoLyrics: _prefs.getBool('autoLyrics') ?? false,
        showUndoSnackbar: _prefs.getBool('showUndoSnackbar') ?? true,
        deviceName: _prefs.getString('deviceName'),
      );

  Future<void> writeSettings(AppSettings s) async {
    await _prefs.setString('theme', s.theme);
    await _prefs.setDouble('fontScale', s.fontScale);
    await _prefs.setBool('compactMode', s.compactMode);
    await _prefs.setBool('reducedMotion', s.reducedMotion);
    await _prefs.setString('language', s.language);
    await _prefs.setBool('autoEnrich', s.autoEnrich);
    await _prefs.setBool('autoLyrics', s.autoLyrics);
    await _prefs.setBool('showUndoSnackbar', s.showUndoSnackbar);
    final dn = s.deviceName;
    if (dn == null || dn.isEmpty) {
      await _prefs.remove('deviceName');
    } else {
      await _prefs.setString('deviceName', dn);
    }
  }

  SavedPlayback readPlayback() {
    final ids = (_prefs.getStringList('lastQueueIds') ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final repeat = PlayRepeat.values.firstWhere(
      (r) => r.name == _prefs.getString('repeat'),
      orElse: () => PlayRepeat.off,
    );
    return SavedPlayback(
      queueIds: ids,
      index: _prefs.getInt('lastIndex') ?? 0,
      positionMs: _prefs.getInt('lastPositionMs') ?? 0,
      volume: _prefs.getDouble('volume') ?? 1.0,
      shuffle: _prefs.getBool('shuffle') ?? false,
      repeat: repeat,
    );
  }

  Future<void> writePlayback(SavedPlayback s) async {
    await _prefs.setStringList(
        'lastQueueIds', [for (final id in s.queueIds) '$id']);
    await _prefs.setInt('lastIndex', s.index);
    await _prefs.setInt('lastPositionMs', s.positionMs);
    await _prefs.setDouble('volume', s.volume);
    await _prefs.setBool('shuffle', s.shuffle);
    await _prefs.setString('repeat', s.repeat.name);
  }
}
