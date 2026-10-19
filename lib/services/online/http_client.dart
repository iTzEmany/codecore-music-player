import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/app_log.dart';

/// Thrown on HTTP 403/429 so batches can stop and warn the user.
class RateLimitedException implements Exception {
  const RateLimitedException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'RateLimitedException($statusCode)';
}

/// Network seam used by every online client (faked in tests).
abstract class WebClient {
  /// Decoded JSON, or null on 404 / network errors.
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel});

  /// Raw bytes for https URLs up to [maxBytes]; null otherwise.
  Future<List<int>?> getBytes(String url,
      {int maxBytes = 5 * 1024 * 1024, CancelToken? cancel});
}

class DioWebClient implements WebClient {
  DioWebClient([Dio? dio, Future<void> Function(Duration)? pause])
      : _pause = pause ?? Future<void>.delayed,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'User-Agent': userAgent},
              validateStatus: (_) => true,
            ));

  static const userAgent = 'Codecore/1.0 (uso personale)';

  final Dio _dio;
  final Future<void> Function(Duration) _pause;

  /// A 429 that names a short wait («retry-after») is waited out, twice at
  /// most; a longer one, or a 403, is reported at once.
  static const _maxRetries = 2;
  static const _maxWait = Duration(seconds: 10);

  void _checkRateLimit(int? code, [String? url, String? retryAfter, Object? body]) {
    if (code == 403 || code == 429) {
      final text = '$body';
      AppLog.w('HTTP $code from ${Uri.tryParse(url ?? '')?.host} (retry-after: $retryAfter): '
          '${text.length > 160 ? text.substring(0, 160) : text}');
      throw RateLimitedException(code!);
    }
  }

  @override
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel}) async {
    try {
      for (var attempt = 0;; attempt++) {
        final res = await _dio.get<Object?>(url,
            queryParameters: query,
            cancelToken: cancel,
            options: Options(responseType: ResponseType.json));
        final wait = res.statusCode == 429
            ? Duration(seconds: int.tryParse(res.headers.value('retry-after') ?? '') ?? 2)
            : null;
        if (wait != null && wait <= _maxWait && attempt < _maxRetries) {
          AppLog.i('HTTP 429 from ${Uri.tryParse(url)?.host}: waiting ${wait.inSeconds} s');
          await _pause(wait);
          continue;
        }
        _checkRateLimit(res.statusCode, url, res.headers.value('retry-after'), res.data);
        if (res.statusCode != 200) return null;
        return decodeJsonBody(res.data);
      }
    } on DioException catch (e, st) {
      if (CancelToken.isCancel(e)) rethrow;
      AppLog.w('GET failed: $url', e, st);
      return null;
    }
  }

  @override
  Future<List<int>?> getBytes(String url,
      {int maxBytes = 5 * 1024 * 1024, CancelToken? cancel}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return null;
    try {
      final res = await _dio.get<List<int>>(url,
          cancelToken: cancel,
          options: Options(responseType: ResponseType.bytes));
      _checkRateLimit(res.statusCode);
      final data = res.data;
      if (res.statusCode != 200 || data == null || data.length > maxBytes) {
        return null;
      }
      return data;
    } on DioException catch (e, st) {
      if (CancelToken.isCancel(e)) rethrow;
      AppLog.w('GET bytes failed: $url', e, st);
      return null;
    }
  }
}

/// Some APIs (iTunes) send JSON as `text/javascript`, which Dio leaves as text.
Object? decodeJsonBody(Object? data) {
  if (data is String) {
    try {
      return jsonDecode(data);
    } on FormatException catch (e) {
      AppLog.w('invalid JSON body', e);
      return null;
    }
  }
  return data;
}

/// Enforces a minimum gap between consecutive calls to [wait].
class RateLimiter {
  RateLimiter({this.minGap = const Duration(seconds: 3)});

  final Duration minGap;
  DateTime? _last;

  Future<void> wait() async {
    final last = _last;
    if (last != null && minGap > Duration.zero) {
      final remaining = minGap - DateTime.now().difference(last);
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    }
    _last = DateTime.now();
  }
}
