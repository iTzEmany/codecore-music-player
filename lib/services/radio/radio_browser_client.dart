import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import '../online/request_budget.dart' show apiUserAgent;
import 'radio_station.dart';

/// Radio Browser is rate limiting us or down for maintenance (429 / 503).
class RadioUnavailable implements Exception {
  const RadioUnavailable([this.retryAfter]);

  final Duration? retryAfter;

  @override
  String toString() => 'RadioUnavailable(retryAfter: $retryAfter)';
}

/// No server could be reached.
class RadioOffline implements Exception {
  const RadioOffline();

  @override
  String toString() => 'RadioOffline';
}

/// A server answered with something that is not the JSON we expect.
class RadioChanged implements Exception {
  const RadioChanged(this.detail);

  final String detail;

  @override
  String toString() => 'RadioChanged($detail)';
}

class RadioCountry {
  const RadioCountry({required this.name, required this.code, required this.stationCount});

  final String name, code;
  final int stationCount;
}

class RadioState {
  const RadioState({required this.name, required this.stationCount});

  final String name;
  final int stationCount;
}

const kRadioFallbackServer = 'de1.api.radio-browser.info';
const _discoveryUrl = 'https://all.api.radio-browser.info/json/servers';

/// Radio Browser (public, no key). One request per user action; the server is
/// picked at random among the advertised ones and kept for the session, the
/// next one is tried on a network error or a 5xx, and [kRadioFallbackServer]
/// is always the last resort.
class RadioBrowserClient {
  RadioBrowserClient(
    this._dio, {
    Random? random,
    this.minGap = const Duration(seconds: 1),
    DateTime Function()? now,
    Future<void> Function(Duration)? pause,
  })  : _random = random ?? Random(),
        _now = now ?? DateTime.now,
        _pause = pause ?? Future<void>.delayed;

  /// A client with the timeouts and the identity every request of the app uses.
  factory RadioBrowserClient.standard() => RadioBrowserClient(Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (_) => true,
      )));

  final Dio _dio;
  final Random _random;
  final Duration minGap;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _pause;

  List<String>? _hosts;
  int _current = 0;
  Future<void> _tail = Future.value();
  DateTime? _last;

  /// The servers advertised by the discovery address (names, without repeats).
  Future<List<String>> servers() async {
    final Object? body;
    try {
      body = await _get(_discoveryUrl, const {});
    } on _ServerDown {
      throw const RadioOffline();
    }
    final names = <String>{
      if (body is List)
        for (final e in body)
          if (e is Map && e['name'] is String && (e['name'] as String).isNotEmpty)
            e['name'] as String,
    };
    return names.toList();
  }

  Future<List<RadioCountry>> countries() async {
    final body = await _api('countries', const {});
    return [
      for (final e in _list(body))
        if (e['name'] is String && e['iso_3166_1'] is String)
          RadioCountry(
            name: e['name'] as String,
            code: (e['iso_3166_1'] as String).toUpperCase(),
            stationCount: (e['stationcount'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

  /// Regions as the stations typed them. Takes the country's English name.
  Future<List<RadioState>> states(String countryName) async {
    final body = await _api('states/${Uri.encodeComponent(countryName)}/',
        {'order': 'stationcount', 'reverse': 'true'});
    return [
      for (final e in _list(body))
        if (e['name'] is String && (e['name'] as String).trim().isNotEmpty)
          RadioState(
              name: (e['name'] as String).trim(),
              stationCount: (e['stationcount'] as num?)?.toInt() ?? 0),
    ];
  }

  Future<List<RadioStation>> byCountry(String countryCode, {int limit = 3000}) =>
      search(countryCode: countryCode, limit: limit);

  Future<List<RadioStation>> search({
    String? name,
    String? countryCode,
    String? tag,
    int limit = 50,
  }) async {
    final body = await _api('stations/search', {
      'name': ?name,
      'countrycode': ?countryCode,
      'tag': ?tag,
      'order': 'clickcount',
      'reverse': 'true',
      'limit': '$limit',
    });
    return _stations(body);
  }

  Future<List<RadioStation>> byUuids(List<String> ids) async {
    if (ids.isEmpty) return const [];
    return _stations(await _api('stations/byuuid', {'uuids': ids.join(',')}));
  }

  /// Counts one listen (the courtesy Radio Browser asks for).
  Future<void> click(String id) async {
    await _api('url/${Uri.encodeComponent(id)}', const {}, hideBroken: false);
  }

  List<RadioStation> _stations(Object? body) => [
        for (final e in _list(body)) ?RadioStation.fromApi(e),
      ];

  List<Map> _list(Object? body) {
    if (body is! List) throw RadioChanged('expected a list, got ${body.runtimeType}');
    return [for (final e in body) if (e is Map) e];
  }

  Future<List<String>> _hostList() async {
    final known = _hosts;
    if (known != null) return known;
    var names = <String>[];
    try {
      names = await servers();
    } on Object catch (e) {
      AppLog.w('Radio Browser discovery failed, using $kRadioFallbackServer', e);
    }
    names.shuffle(_random);
    if (!names.contains(kRadioFallbackServer)) names.add(kRadioFallbackServer);
    return _hosts = names;
  }

  Future<Object?> _api(String path, Map<String, String> query, {bool hideBroken = true}) async {
    final hosts = await _hostList();
    final params = {...query, if (hideBroken) 'hidebroken': 'true'};
    for (var i = 0; i < hosts.length; i++) {
      final host = hosts[(_current + i) % hosts.length];
      try {
        final body = await _get('https://$host/json/$path', params);
        _current = (_current + i) % hosts.length;
        return body;
      } on _ServerDown catch (e) {
        AppLog.w('Radio Browser $host: $e');
      }
    }
    throw const RadioOffline();
  }

  /// One request, one at a time and at least [minGap] apart.
  Future<Object?> _get(String url, Map<String, String> query) {
    final run = _tail.then((_) async {
      final last = _last;
      if (last != null) {
        final wait = minGap - _now().difference(last);
        if (wait > Duration.zero) await _pause(wait);
      }
      try {
        return await _send(url, query);
      } finally {
        _last = _now();
      }
    });
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<Object?> _send(String url, Map<String, String> query) async {
    final Response<Object?> res;
    try {
      res = await _dio.get<Object?>(
        url,
        queryParameters: query,
        options: Options(
          responseType: ResponseType.json,
          headers: {'User-Agent': apiUserAgent},
        ),
      );
    } on DioException catch (e) {
      if (e.error is FormatException) throw RadioChanged('invalid JSON: ${e.error}');
      throw _ServerDown(e.type.name);
    }
    final code = res.statusCode ?? 0;
    if (code == 429 || code == 503) {
      final secs = int.tryParse(res.headers.value('retry-after') ?? '');
      throw RadioUnavailable(secs == null ? null : Duration(seconds: secs));
    }
    if (code >= 500) throw _ServerDown('HTTP $code');
    if (code != 200) throw RadioChanged('HTTP $code');
    final data = res.data;
    if (data is List || data is Map) return data;
    throw RadioChanged('not JSON: ${data.runtimeType}');
  }
}

class _ServerDown implements Exception {
  const _ServerDown(this.what);

  final String what;

  @override
  String toString() => what;
}
