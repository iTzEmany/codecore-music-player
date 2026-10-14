import 'dart:async';

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
  DioWebClient([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'User-Agent': userAgent},
              validateStatus: (_) => true,
            ));

  static const userAgent = 'Codecore/1.0 (uso personale)';

  final Dio _dio;

  void _checkRateLimit(int? code) {
    if (code == 403 || code == 429) throw RateLimitedException(code!);
  }

  @override
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel}) async {
    try {
      final res = await _dio.get<Object?>(url,
          queryParameters: query,
          cancelToken: cancel,
          options: Options(responseType: ResponseType.json));
      _checkRateLimit(res.statusCode);
      if (res.statusCode != 200) return null;
      return res.data;
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
