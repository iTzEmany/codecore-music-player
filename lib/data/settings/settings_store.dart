import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/audio/play_queue.dart';

class AppSettings {
  const AppSettings({
    this.theme = 'notte',
    this.fontScale = 1.0,
    this.compactMode = false,
    this.reducedMotion = false,
    this.language = 'it',
    this.autoEnrich = false,
    this.autoLyrics = false,
    this.showUndoSnackbar = true,
    this.deviceName,
    this.jamLatencyMs = 0,
    this.normalizeVolume = false,
    this.receiveFromLan = false,
    this.librarySort = 'recent',
    this.libraryGrid = false,
    this.recentSearches = const [],
    this.ytNoticeSeen = false,
    this.downloadParallel = 2,
    this.downloadRateLimitKBps = 0,
    this.downloadOriginal = false,
  });

  final String theme;
  final double fontScale;
  final bool compactMode, reducedMotion, autoEnrich, autoLyrics, showUndoSnackbar;

  /// Applies ReplayGain (track gain) at playback time.
  final bool normalizeVolume;

  /// Listen for offers from nearby devices while the app is open.
  final bool receiveFromLan;
  final String language;

  /// Library order: `recent` | `alpha` | `added`.
  final String librarySort;

  /// Library as a grid instead of a list.
  final bool libraryGrid;

  /// Latest library searches, newest first (max 10).
  final List<String> recentSearches;

  /// The YouTube legal notice was dismissed once.
  final bool ytNoticeSeen;

  /// Downloads running at once (1–3).
  final int downloadParallel;

  /// Download speed cap in KB/s; 0 = none.
  final int downloadRateLimitKBps;

  /// Keep the downloaded audio as served instead of converting to MP3.
  final bool downloadOriginal;

  /// Shown to the device on the other side of a LAN share; null = hostname.
  final String? deviceName;

  /// Extra output latency of this device in a synchronised Jam (ms).
  final int jamLatencyMs;

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
    int? jamLatencyMs,
    bool? normalizeVolume,
    bool? receiveFromLan,
    String? librarySort,
    bool? libraryGrid,
    List<String>? recentSearches,
    bool? ytNoticeSeen,
    int? downloadParallel,
    int? downloadRateLimitKBps,
    bool? downloadOriginal,
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
        jamLatencyMs: jamLatencyMs ?? this.jamLatencyMs,
        normalizeVolume: normalizeVolume ?? this.normalizeVolume,
        receiveFromLan: receiveFromLan ?? this.receiveFromLan,
        librarySort: librarySort ?? this.librarySort,
        libraryGrid: libraryGrid ?? this.libraryGrid,
        recentSearches: recentSearches ?? this.recentSearches,
        ytNoticeSeen: ytNoticeSeen ?? this.ytNoticeSeen,
        downloadParallel: downloadParallel ?? this.downloadParallel,
        downloadRateLimitKBps:
            downloadRateLimitKBps ?? this.downloadRateLimitKBps,
        downloadOriginal: downloadOriginal ?? this.downloadOriginal,
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
        theme: _prefs.getString('theme') ?? 'notte',
        fontScale: _prefs.getDouble('fontScale') ?? 1.0,
        compactMode: _prefs.getBool('compactMode') ?? false,
        reducedMotion: _prefs.getBool('reducedMotion') ?? false,
        language: _prefs.getString('language') ?? 'it',
        autoEnrich: _prefs.getBool('autoEnrich') ?? false,
        autoLyrics: _prefs.getBool('autoLyrics') ?? false,
        showUndoSnackbar: _prefs.getBool('showUndoSnackbar') ?? true,
        deviceName: _prefs.getString('deviceName'),
        normalizeVolume: _prefs.getBool('normalizeVolume') ?? false,
        receiveFromLan: _prefs.getBool('receiveFromLan') ?? false,
        jamLatencyMs: _prefs.getInt('jamLatencyMs') ?? 0,
        librarySort: _prefs.getString('librarySort') ?? 'recent',
        libraryGrid: _prefs.getBool('libraryGrid') ?? false,
        recentSearches: _prefs.getStringList('recentSearches') ?? const [],
        ytNoticeSeen: _prefs.getBool('ytNoticeSeen') ?? false,
        downloadParallel:
            (_prefs.getInt('downloadParallel') ?? 2).clamp(1, 3),
        downloadRateLimitKBps: _prefs.getInt('downloadRateLimitKBps') ?? 0,
        downloadOriginal: _prefs.getBool('downloadOriginal') ?? false,
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
    await _prefs.setBool('normalizeVolume', s.normalizeVolume);
    await _prefs.setBool('receiveFromLan', s.receiveFromLan);
    await _prefs.setInt('jamLatencyMs', s.jamLatencyMs);
    await _prefs.setString('librarySort', s.librarySort);
    await _prefs.setBool('libraryGrid', s.libraryGrid);
    await _prefs.setStringList('recentSearches', s.recentSearches);
    await _prefs.setBool('ytNoticeSeen', s.ytNoticeSeen);
    await _prefs.setInt('downloadParallel', s.downloadParallel);
    await _prefs.setInt('downloadRateLimitKBps', s.downloadRateLimitKBps);
    await _prefs.setBool('downloadOriginal', s.downloadOriginal);
    final dn = s.deviceName;
    if (dn == null || dn.isEmpty) {
      await _prefs.remove('deviceName');
    } else {
      await _prefs.setString('deviceName', dn);
    }
  }

  /// Stable random id of this installation (used to recognise devices).
  Future<String> deviceId() async {
    final existing = _prefs.getString('deviceId');
    if (existing != null && existing.length >= 16) return existing;
    final r = Random.secure();
    final id = List.generate(16, (_) => r.nextInt(256))
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
    await _prefs.setString('deviceId', id);
    return id;
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
