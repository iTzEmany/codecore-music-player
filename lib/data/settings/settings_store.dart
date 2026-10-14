import 'package:shared_preferences/shared_preferences.dart';

import '../../services/audio/play_queue.dart';

class SavedPlayback {
  const SavedPlayback({
    this.queueIds = const [],
    this.index = 0,
    this.positionMs = 0,
    this.volume = 1.0,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
  });

  final List<int> queueIds;
  final int index, positionMs;
  final double volume;
  final bool shuffle;
  final RepeatMode repeat;
}

class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStore> open() async =>
      SettingsStore(await SharedPreferences.getInstance());

  SavedPlayback readPlayback() {
    final ids = (_prefs.getStringList('lastQueueIds') ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final repeat = RepeatMode.values.firstWhere(
      (r) => r.name == _prefs.getString('repeat'),
      orElse: () => RepeatMode.off,
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
