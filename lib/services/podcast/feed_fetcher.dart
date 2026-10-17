import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import '../online/http_client.dart';
import 'podcast_models.dart';

/// The real [FeedFetcher]: a GET that reads the answer as a stream and stops
/// as soon as it is bigger than [maxBytes] (a feed is text, never 20 MB of it
/// by accident). Text is decoded as UTF-8, tolerating bad bytes.
FeedFetcher dioFeedFetcher({Dio? dio, int maxBytes = maxFeedBytes}) {
  final client = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'User-Agent': DioWebClient.userAgent},
        followRedirects: true,
        validateStatus: (_) => true,
      ));
  return (url) async {
    final Response<ResponseBody> res;
    try {
      res = await client.get<ResponseBody>(url,
          options: Options(responseType: ResponseType.stream));
    } on DioException catch (e, st) {
      AppLog.w('feed request failed: $url', e, st);
      throw PodcastException(PodcastErrorKind.network, e.message);
    }
    final code = res.statusCode ?? 0;
    final body = res.data;
    if (code != 200 || body == null) {
      throw PodcastException(PodcastErrorKind.network, 'HTTP $code');
    }
    final declared = int.tryParse(res.headers.value('content-length') ?? '');
    if (declared != null && declared > maxBytes) {
      throw PodcastException(PodcastErrorKind.tooLarge, '$declared bytes');
    }
    final bytes = <int>[];
    try {
      await for (final chunk in body.stream) {
        bytes.addAll(chunk);
        if (bytes.length > maxBytes) {
          throw PodcastException(PodcastErrorKind.tooLarge, '> $maxBytes bytes');
        }
      }
    } on DioException catch (e, st) {
      AppLog.w('feed download failed: $url', e, st);
      throw PodcastException(PodcastErrorKind.network, e.message);
    }
    return utf8.decode(bytes, allowMalformed: true);
  };
}
