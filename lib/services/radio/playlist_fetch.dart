import 'dart:convert';

import 'package:dio/dio.dart';

import 'stream_link.dart';

/// Downloads a `.pls` / `.m3u` file for [resolveStreamLink]: the first
/// [kMaxPlaylistBytes] + 1 bytes at most, so a huge answer is refused as too
/// big without being read to the end.
Future<String> fetchPlaylistText(Uri url, {Dio? dio}) async {
  final client = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        responseType: ResponseType.stream,
      ));
  final res = await client.getUri<ResponseBody>(url);
  final code = res.statusCode ?? 0;
  if (code < 200 || code >= 300) throw const StreamLinkException(StreamLinkError.fetchFailed);
  final bytes = <int>[];
  await for (final chunk in res.data!.stream) {
    bytes.addAll(chunk);
    if (bytes.length > kMaxPlaylistBytes) {
      throw const StreamLinkException(StreamLinkError.tooBig);
    }
  }
  return utf8.decode(bytes, allowMalformed: true);
}
