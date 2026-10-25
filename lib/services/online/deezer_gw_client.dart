import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_log.dart';
import 'credits.dart';
import 'deezer_client.dart' show DeezerNetworkException;
import 'http_client.dart';
import 'request_budget.dart' show apiUserAgent;

/// The session token was refused even after a fresh session.
class DeezerGwTokenException implements Exception {
  const DeezerGwTokenException();

  @override
  String toString() => 'DeezerGwTokenException()';
}

/// The answer was not what this client knows how to read.
class DeezerGwFormatException implements Exception {
  const DeezerGwFormatException(this.detail);

  final String detail;

  @override
  String toString() => 'DeezerGwFormatException($detail)';
}

/// The 24-hour pause is on: no request was made.
class DeezerGwPausedException implements Exception {
  const DeezerGwPausedException();

  @override
  String toString() => 'DeezerGwPausedException()';
}

/// Deezer's own web endpoint (`gw-light`) for the credits the public API lacks.
/// Anonymous session, undocumented: 3 errors in a row pause it for 24 hours
/// (kept across restarts). A valid answer with no contributors is an empty
/// result, never an exception.
class DeezerGwClient {
  DeezerGwClient({
    Dio? dio,
    Future<SharedPreferences> Function()? prefs,
    DateTime Function()? now,
    this.onPaused,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 8),
               receiveTimeout: const Duration(seconds: 15),
               responseType: ResponseType.plain,
               validateStatus: (_) => true,
             ),
           ),
       _prefs = prefs ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now;

  static const pauseKey = 'deezerGwPausedUntil';
  static const pause = Duration(hours: 24);
  static const maxErrors = 3;
  static const _url = 'https://www.deezer.com/ajax/gw-light.php';

  final Dio _dio;
  final Future<SharedPreferences> Function() _prefs;
  final DateTime Function() _now;

  /// Called once when the pause starts.
  final void Function()? onPaused;

  String? _token;
  String? _sid;
  int _errors = 0;
  DateTime? _pausedUntil;
  bool _loaded = false;

  /// Reflects the stored pause once any call (or [load]) has read it.
  bool get isPaused => _pausedUntil != null && _now().isBefore(_pausedUntil!);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final ms = (await _prefs()).getInt(pauseKey);
    if (ms != null) _pausedUntil = DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Contributors of Deezer track [sngId]. Throws [DeezerGwPausedException],
  /// [RateLimitedException] (not counted as an error), [DeezerNetworkException],
  /// [DeezerGwFormatException] or [DeezerGwTokenException].
  Future<DeezerContributors> pageTrack(int sngId) async {
    await load();
    if (isPaused) throw const DeezerGwPausedException();
    try {
      final data = await _pageTrack(sngId);
      _errors = 0;
      return parseDeezerContributors(data);
    } on RateLimitedException {
      rethrow;
    } catch (e) {
      AppLog.w('deezer_gw: pageTrack $sngId failed', e);
      if (++_errors >= maxErrors) await _enterPause();
      rethrow;
    }
  }

  Future<void> _enterPause() async {
    _errors = 0;
    _pausedUntil = _now().add(pause);
    await (await _prefs()).setInt(
      pauseKey,
      _pausedUntil!.millisecondsSinceEpoch,
    );
    onPaused?.call();
  }

  Future<Map<String, dynamic>> _pageTrack(int sngId) async {
    if (_token == null) await _newSession();
    for (var renewed = false; ; renewed = true) {
      try {
        final r = await _call('deezer.pageTrack', {
          'sng_id': '$sngId',
        }, token: _token!);
        final data = r['DATA'];
        if (data is! Map<String, dynamic>) {
          throw const DeezerGwFormatException('no DATA');
        }
        return data;
      } on DeezerGwTokenException {
        if (renewed) rethrow;
        await _newSession();
      }
    }
  }

  Future<void> _newSession() async {
    _sid = null;
    final r = await _call(
      'deezer.getUserData',
      const {},
      token: '',
      session: true,
    );
    final token = r['checkForm'];
    if (token is! String || token.isEmpty || _sid == null) {
      throw const DeezerGwFormatException('no session');
    }
    _token = token;
  }

  Future<Map<String, dynamic>> _call(
    String method,
    Map<String, String> body, {
    required String token,
    bool session = false,
  }) async {
    final Response<String> res;
    try {
      res = await _dio.post<String>(
        _url,
        queryParameters: {
          'method': method,
          'input': '3',
          'api_version': '1.0',
          'api_token': token,
        },
        data: jsonEncode(body), // an empty body is refused with a 400
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          headers: {
            'User-Agent': apiUserAgent,
            'Content-Type': 'application/json',
            if (!session) 'Cookie': 'sid=$_sid',
          },
        ),
      );
    } on DioException catch (e) {
      throw DeezerNetworkException('$method: ${e.type.name}');
    }
    final code = res.statusCode ?? 0;
    if (code == 429) throw RateLimitedException(code);
    if (code != 200) throw DeezerNetworkException('$method: HTTP $code');
    if (session) {
      for (final c in res.headers['set-cookie'] ?? const <String>[]) {
        final m = RegExp(r'(?:^|[\s;,])sid=([^;,\s]+)').firstMatch(c);
        if (m != null) _sid = m.group(1);
      }
    }
    final Object? json;
    try {
      json = jsonDecode(res.data ?? '');
    } on FormatException {
      throw DeezerGwFormatException('$method: not JSON');
    }
    if (json is! Map) throw DeezerGwFormatException('$method: not an object');
    final error = json['error'];
    if (error is Map && error.isNotEmpty) {
      if (error.containsKey('VALID_TOKEN_REQUIRED')) {
        throw const DeezerGwTokenException();
      }
      throw DeezerGwFormatException('$method: ${error.keys.join(',')}');
    }
    final results = json['results'];
    if (results is! Map<String, dynamic>) {
      throw DeezerGwFormatException('$method: no results');
    }
    return results;
  }
}
