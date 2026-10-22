import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/audio/audio_backend.dart' show TransitionMode;
import '../../services/audio/equalizer.dart';
import '../../services/audio/play_queue.dart';
import '../../services/online/youtube_service.dart' show DownloadFormat, SearchSource;

/// The equalizer curve chosen for one kind of output (speaker or headphones).
class EqProfile {
  const EqProfile({this.preset = EqPreset.flat, this.custom = const []});

  final EqPreset preset;

  /// The user's own gains in dB, one per band (used when [preset] is custom).
  final List<double> custom;

  EqProfile copyWith({EqPreset? preset, List<double>? custom}) =>
      EqProfile(preset: preset ?? this.preset, custom: custom ?? this.custom);
}

class AppSettings {
  const AppSettings({
    this.theme = 'notte',
    this.accent = 'viola',
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
    this.onboardingDone = false,
    this.recordHistory = true,
    this.downloadParallel = 2,
    this.downloadRateLimitKBps = 0,
    this.downloadFormat = DownloadFormat.m4a,
    this.importSureThreshold = 0.80,
    this.importReviewThreshold = 0.55,
    this.playbackSpeed = 1.0,
    this.eqEnabled = false,
    this.eqSpeaker = const EqProfile(),
    this.eqHeadphones = const EqProfile(),
    this.transition = TransitionMode.normal,
    this.crossfadeSeconds = 6,
    this.crossfadePlainInAlbum = true,
    this.searchSource = SearchSource.youtube,
    this.importSoundCloud = false,
    this.writeTagsToFiles = false,
    this.tagsAlsoInFile = true,
    this.shufflePlus = false,
    this.shufflePlusEvery = 4,
    this.shufflePlusUnmeteredOnly = true,
    this.radioCountry = '',
    this.radioRegion = '',
    this.radioOnlyCountry = false,
  });

  final String theme;

  /// The first-run guide was finished or skipped (never shown again).
  final bool onboardingDone;

  /// Keep the listening history (`plays`); local only.
  final bool recordHistory;

  /// One of the eight accent names (`CcAccent`); unknown ones mean violet.
  final String accent;
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

  /// M4A keeps YouTube's AAC as served; MP3 converts for players that need it.
  final DownloadFormat downloadFormat;

  /// CSV import: score from which a match is downloaded without asking, and
  /// from which it is at least proposed (advanced settings).
  final double importSureThreshold, importReviewThreshold;

  /// Playback speed (0.5–2.0), the same for every track; tone is preserved.
  final double playbackSpeed;

  /// Equalizer on/off (Android) and its curve for each kind of output.
  final bool eqEnabled;
  final EqProfile eqSpeaker, eqHeadphones;

  /// How one track gives way to the next, and the length of a crossfade.
  final TransitionMode transition;
  final int crossfadeSeconds;

  /// Inside an album the tracks follow each other plainly, with no fade.
  final bool crossfadePlainInAlbum;

  /// Shuffle+ (phase 31): with shuffle on, a song you do not have every
  /// [shufflePlusEvery] songs (3–10); [shufflePlusUnmeteredOnly] keeps it off
  /// mobile data.
  final bool shufflePlus, shufflePlusUnmeteredOnly;
  final int shufflePlusEvery;

  /// Radio (phase 33): the country (ISO code; empty = the system's) and the
  /// region id chosen for «Vicino a te» (empty = still to ask); search only
  /// inside the country.
  final String radioCountry, radioRegion;
  final bool radioOnlyCountry;

  /// Where the online search of the Search page looks.
  final SearchSource searchSource;

  /// CSV import: try SoundCloud for the rows YouTube did not find.
  final bool importSoundCloud;

  /// Edits of title, artist, album… are also written into the music files
  /// (through `SafeTagWriter`, with a backup). Off by default.
  final bool writeTagsToFiles;

  /// With [writeTagsToFiles] on: the last answer to «also in the file?».
  final bool tagsAlsoInFile;

  /// Shown to the device on the other side of a LAN share; null = hostname.
  final String? deviceName;

  /// Extra output latency of this device in a synchronised Jam (ms).
  final int jamLatencyMs;

  AppSettings copyWith({
    String? theme,
    String? accent,
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
    bool? onboardingDone,
    bool? recordHistory,
    int? downloadParallel,
    int? downloadRateLimitKBps,
    DownloadFormat? downloadFormat,
    double? importSureThreshold,
    double? importReviewThreshold,
    double? playbackSpeed,
    bool? eqEnabled,
    EqProfile? eqSpeaker,
    EqProfile? eqHeadphones,
    TransitionMode? transition,
    int? crossfadeSeconds,
    bool? crossfadePlainInAlbum,
    SearchSource? searchSource,
    bool? importSoundCloud,
    bool? writeTagsToFiles,
    bool? tagsAlsoInFile,
    bool? shufflePlus,
    int? shufflePlusEvery,
    bool? shufflePlusUnmeteredOnly,
    String? radioCountry,
    String? radioRegion,
    bool? radioOnlyCountry,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        accent: accent ?? this.accent,
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
        onboardingDone: onboardingDone ?? this.onboardingDone,
        recordHistory: recordHistory ?? this.recordHistory,
        downloadParallel: downloadParallel ?? this.downloadParallel,
        downloadRateLimitKBps:
            downloadRateLimitKBps ?? this.downloadRateLimitKBps,
        downloadFormat: downloadFormat ?? this.downloadFormat,
        importSureThreshold: importSureThreshold ?? this.importSureThreshold,
        importReviewThreshold:
            importReviewThreshold ?? this.importReviewThreshold,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        eqEnabled: eqEnabled ?? this.eqEnabled,
        eqSpeaker: eqSpeaker ?? this.eqSpeaker,
        eqHeadphones: eqHeadphones ?? this.eqHeadphones,
        transition: transition ?? this.transition,
        crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
        crossfadePlainInAlbum:
            crossfadePlainInAlbum ?? this.crossfadePlainInAlbum,
        searchSource: searchSource ?? this.searchSource,
        importSoundCloud: importSoundCloud ?? this.importSoundCloud,
        writeTagsToFiles: writeTagsToFiles ?? this.writeTagsToFiles,
        tagsAlsoInFile: tagsAlsoInFile ?? this.tagsAlsoInFile,
        shufflePlus: shufflePlus ?? this.shufflePlus,
        shufflePlusEvery: shufflePlusEvery ?? this.shufflePlusEvery,
        shufflePlusUnmeteredOnly:
            shufflePlusUnmeteredOnly ?? this.shufflePlusUnmeteredOnly,
        radioCountry: radioCountry ?? this.radioCountry,
        radioRegion: radioRegion ?? this.radioRegion,
        radioOnlyCountry: radioOnlyCountry ?? this.radioOnlyCountry,
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
        accent: _prefs.getString('accent') ?? 'viola',
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
        onboardingDone: _prefs.getBool('onboardingDone') ?? false,
        recordHistory: _prefs.getBool('recordHistory') ?? true,
        downloadParallel:
            (_prefs.getInt('downloadParallel') ?? 2).clamp(1, 3),
        downloadRateLimitKBps: _prefs.getInt('downloadRateLimitKBps') ?? 0,
        // The old «downloadOriginal» switch is not read: MP3 was only ever the
        // default, so everyone moves to M4A.
        downloadFormat: DownloadFormat.values.firstWhere(
          (f) => f.name == _prefs.getString('downloadFormat'),
          orElse: () => DownloadFormat.m4a,
        ),
        importSureThreshold: _prefs.getDouble('importSureThreshold') ?? 0.80,
        importReviewThreshold: _prefs.getDouble('importReviewThreshold') ?? 0.55,
        playbackSpeed:
            (_prefs.getDouble('playbackSpeed') ?? 1.0).clamp(0.5, 2.0),
        eqEnabled: _prefs.getBool('eqEnabled') ?? false,
        eqSpeaker: _readEq('speaker'),
        eqHeadphones: _readEq('headphones'),
        transition: TransitionMode.values.firstWhere(
          (m) => m.name == _prefs.getString('transition'),
          orElse: () => TransitionMode.normal,
        ),
        crossfadeSeconds: (_prefs.getInt('crossfadeSeconds') ?? 6).clamp(2, 12),
        crossfadePlainInAlbum: _prefs.getBool('crossfadePlainInAlbum') ?? true,
        searchSource: SearchSource.values.firstWhere(
          (m) => m.name == _prefs.getString('searchSource'),
          orElse: () => SearchSource.youtube,
        ),
        importSoundCloud: _prefs.getBool('importSoundCloud') ?? false,
        writeTagsToFiles: _prefs.getBool('writeTagsToFiles') ?? false,
        tagsAlsoInFile: _prefs.getBool('tagsAlsoInFile') ?? true,
        shufflePlus: _prefs.getBool('shufflePlus') ?? false,
        shufflePlusEvery: (_prefs.getInt('shufflePlusEvery') ?? 4).clamp(3, 10),
        shufflePlusUnmeteredOnly: _prefs.getBool('shufflePlusUnmeteredOnly') ?? true,
        radioCountry: _prefs.getString('radioCountry') ?? '',
        radioRegion: _prefs.getString('radioRegion') ?? '',
        radioOnlyCountry: _prefs.getBool('radioOnlyCountry') ?? false,
      );

  EqProfile _readEq(String profile) => EqProfile(
        preset: EqPreset.values.firstWhere(
          (p) => p.name == _prefs.getString('eqPreset.$profile'),
          orElse: () => EqPreset.flat,
        ),
        custom: [
          for (final g in _prefs.getStringList('eqGains.$profile') ?? const [])
            ?double.tryParse(g),
        ],
      );

  Future<void> _writeEq(String profile, EqProfile p) async {
    await _prefs.setString('eqPreset.$profile', p.preset.name);
    await _prefs.setStringList(
        'eqGains.$profile', [for (final g in p.custom) '$g']);
  }

  Future<void> writeSettings(AppSettings s) async {
    await _prefs.setString('theme', s.theme);
    await _prefs.setString('accent', s.accent);
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
    await _prefs.setBool('onboardingDone', s.onboardingDone);
    await _prefs.setBool('recordHistory', s.recordHistory);
    await _prefs.setInt('downloadParallel', s.downloadParallel);
    await _prefs.setInt('downloadRateLimitKBps', s.downloadRateLimitKBps);
    await _prefs.setString('downloadFormat', s.downloadFormat.name);
    await _prefs.remove('downloadOriginal');
    await _prefs.setDouble('importSureThreshold', s.importSureThreshold);
    await _prefs.setDouble('importReviewThreshold', s.importReviewThreshold);
    await _prefs.setDouble('playbackSpeed', s.playbackSpeed);
    await _prefs.setBool('eqEnabled', s.eqEnabled);
    await _writeEq('speaker', s.eqSpeaker);
    await _writeEq('headphones', s.eqHeadphones);
    await _prefs.setString('transition', s.transition.name);
    await _prefs.setInt('crossfadeSeconds', s.crossfadeSeconds);
    await _prefs.setBool('crossfadePlainInAlbum', s.crossfadePlainInAlbum);
    await _prefs.setString('searchSource', s.searchSource.name);
    await _prefs.setBool('importSoundCloud', s.importSoundCloud);
    await _prefs.setBool('writeTagsToFiles', s.writeTagsToFiles);
    await _prefs.setBool('tagsAlsoInFile', s.tagsAlsoInFile);
    await _prefs.setBool('shufflePlus', s.shufflePlus);
    await _prefs.setInt('shufflePlusEvery', s.shufflePlusEvery);
    await _prefs.setBool('shufflePlusUnmeteredOnly', s.shufflePlusUnmeteredOnly);
    await _prefs.setString('radioCountry', s.radioCountry);
    await _prefs.setString('radioRegion', s.radioRegion);
    await _prefs.setBool('radioOnlyCountry', s.radioOnlyCountry);
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

  /// The paired devices, as written by `TrustedDevices.encode`.
  String? readTrustedDevicesRaw() => _prefs.getString('trustedDevices');

  Future<void> writeTrustedDevicesRaw(String raw) =>
      _prefs.setString('trustedDevices', raw);

  /// The user's own themes, as written by `CustomThemes.encode`.
  String? readCustomThemesRaw() => _prefs.getString('customThemes');

  Future<void> writeCustomThemesRaw(String raw) => _prefs.setString('customThemes', raw);

  /// «Controlla all'avvio» for new versions: off unless the user turns it on.
  bool readCheckUpdatesOnStart() => _prefs.getBool('checkUpdatesOnStart') ?? false;

  Future<void> writeCheckUpdatesOnStart(bool on) => _prefs.setBool('checkUpdatesOnStart', on);

  /// Day (days since the epoch) of the last check made at start-up.
  int readLastUpdateCheckDay() => _prefs.getInt('lastUpdateCheckDay') ?? 0;

  Future<void> writeLastUpdateCheckDay(int day) => _prefs.setInt('lastUpdateCheckDay', day);

  /// Duplicate groups the user marked «not duplicates» (`DuplicateGroup.key`).
  Set<String> readNotDuplicates() =>
      (_prefs.getStringList('notDuplicates') ?? const []).toSet();

  Future<void> writeNotDuplicates(Set<String> keys) =>
      _prefs.setStringList('notDuplicates', keys.toList()..sort());

  /// Tracks the user marked «va bene così» in «Da revisionare» (track ids).
  Set<int> readReviewDismissed() => (_prefs.getStringList('reviewDismissed') ?? const [])
      .map(int.tryParse)
      .whereType<int>()
      .toSet();

  Future<void> writeReviewDismissed(Set<int> ids) => _prefs.setStringList(
    'reviewDismissed',
    [for (final i in ids.toList()..sort()) '$i'],
  );

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
