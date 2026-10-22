import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import 'near_you.dart';
import 'radio_browser_client.dart';
import 'radio_station.dart';
import 'regions.dart';

/// A list of stations and where it comes from.
class RadioList {
  const RadioList(this.stations, {this.stale = false, this.fetchedAt});

  final List<RadioStation> stations;

  /// Radio Browser could not be reached: this is the saved copy, older than
  /// [RadioCatalog.countryTtl].
  final bool stale;
  final DateTime? fetchedAt;
}

/// The default country: the system locale's, or Italy.
String defaultRadioCountry(String? localeCountryCode) {
  final cc = (localeCountryCode ?? '').trim().toUpperCase();
  return cc.length == 2 ? cc : kItalyCode;
}

/// What the Radio page reads: the country's stations (one download kept for
/// [countryTtl] in `<dir>/country_<CC>.json`) and searches kept in memory.
class RadioCatalog {
  RadioCatalog(
    this._client,
    this.dir, {
    DateTime Function()? now,
    this.countryTtl = const Duration(days: 7),
    this.searchTtl = const Duration(minutes: 10),
    this.searchCapacity = 30,
  }) : _now = now ?? DateTime.now;

  final RadioBrowserClient _client;

  /// `<appSupport>/radio`: the only thing «Svuota cache» deletes.
  final String dir;
  final DateTime Function() _now;
  final Duration countryTtl, searchTtl;
  final int searchCapacity;

  // Insertion order = least recently used first.
  final _searches = <String, (DateTime, List<RadioStation>)>{};

  String _file(String cc) => p.join(dir, 'country_${cc.toUpperCase()}.json');

  /// The stations of [countryCode], without repeats and most listened first;
  /// only those of [region] when given. Reading and filtering run off the UI
  /// thread. Offline with an old copy: the copy, marked stale.
  Future<RadioList> country(String countryCode, {RadioRegion? region}) async {
    final path = _file(countryCode);
    final saved = await Isolate.run(() => _readCountry(path, region));
    final now = _now();
    if (saved != null && now.difference(saved.fetchedAt) < countryTtl) {
      return RadioList(saved.stations, fetchedAt: saved.fetchedAt);
    }
    final List<RadioStation> fresh;
    try {
      fresh = await _client.byCountry(countryCode.toUpperCase());
    } on Object catch (e) {
      if (e is! RadioOffline && e is! RadioUnavailable && e is! RadioChanged) rethrow;
      if (saved == null) rethrow;
      AppLog.w('radio: using the old copy of $countryCode', e);
      return RadioList(saved.stations, stale: true, fetchedAt: saved.fetchedAt);
    }
    final stamp = now.millisecondsSinceEpoch;
    try {
      await Isolate.run(() => _writeCountry(path, stamp, fresh));
    } on Object catch (e, st) {
      AppLog.w('radio: cannot save the list of $countryCode', e, st);
    }
    return RadioList(await Isolate.run(() => _select(fresh, region)), fetchedAt: now);
  }

  /// Search by name (at least 2 characters); the same one within [searchTtl]
  /// is answered from memory.
  Future<List<RadioStation>> search(String query, {String? countryCode}) {
    final q = query.trim();
    if (q.length < 2) return Future.value(const []);
    return _cached('n|${q.toLowerCase()}|${countryCode ?? ''}',
        () => _client.search(name: q, countryCode: countryCode));
  }

  Future<List<RadioStation>> byGenre(String tag, {String? countryCode}) => _cached(
      't|${tag.toLowerCase()}|${countryCode ?? ''}',
      () => _client.search(tag: tag, countryCode: countryCode));

  Future<List<RadioStation>> _cached(
      String key, Future<List<RadioStation>> Function() load) async {
    final hit = _searches.remove(key);
    if (hit != null && _now().difference(hit.$1) < searchTtl) {
      _searches[key] = hit;
      return hit.$2;
    }
    final result = dedupe(await load());
    _searches[key] = (_now(), result);
    while (_searches.length > searchCapacity) {
      _searches.remove(_searches.keys.first);
    }
    return result;
  }

  /// Forgets the in-memory searches (the files are the cache cleaner's).
  void clearMemory() => _searches.clear();
}

class _Saved {
  const _Saved(this.stations, this.fetchedAt);

  final List<RadioStation> stations;
  final DateTime fetchedAt;
}

List<RadioStation> _select(List<RadioStation> all, RadioRegion? region) =>
    region == null ? dedupe(all) : nearYou(all, region);

_Saved? _readCountry(String path, RadioRegion? region) {
  final file = File(path);
  try {
    if (!file.existsSync()) return null;
    final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final all = [
      for (final e in (j['stations'] as List? ?? const []))
        ?RadioStation.fromJson(e as Map),
    ];
    return _Saved(_select(all, region),
        DateTime.fromMillisecondsSinceEpoch((j['fetchedAt'] as num).toInt()));
  } on Object catch (e, st) {
    AppLog.w('radio: unreadable copy $path', e, st);
    return null;
  }
}

void _writeCountry(String path, int fetchedAt, List<RadioStation> stations) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  final tmp = File('$path.tmp');
  tmp.writeAsStringSync(jsonEncode({
    'fetchedAt': fetchedAt,
    'stations': [for (final s in stations) s.toJson()],
  }));
  tmp.renameSync(path);
}
