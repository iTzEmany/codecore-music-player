import 'package:dio/dio.dart';

import 'http_client.dart';
import 'lrclib_client.dart';

/// Plain lyrics from lyrics.ovh, the last fallback (D-111).
class LyricsOvhClient {
  LyricsOvhClient(this._web);

  final WebClient _web;

  static const timeout = Duration(seconds: 8);

  /// Null when unknown or empty; throws when the service fails.
  Future<LyricsResult?> find({
    required String title,
    required String artist,
    CancelToken? cancel,
  }) async {
    if (title.trim().isEmpty || artist.trim().isEmpty) return null;
    final url = Uri(
      scheme: 'https',
      host: 'api.lyrics.ovh',
      pathSegments: ['v1', artist, title],
    ).toString();
    final res = await _web
        .getJson(url, cancel: cancel, strict: true)
        .timeout(timeout);
    final text = res is Map ? res['lyrics'] : null;
    return text is String && text.trim().isNotEmpty
        ? LyricsResult(plain: text.trim())
        : null;
  }
}
