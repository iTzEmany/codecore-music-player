import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import 'http_client.dart';
import 'lrclib_client.dart';
import 'lyrics_ovh_client.dart';
import 'netease_lyrics_client.dart';
import 'query_cleaner.dart';

class LyricsChainResult {
  const LyricsChainResult({this.lyrics, this.failed = false, this.source});

  final LyricsResult? lyrics;

  /// A fallback source errored and there is no text, so «nothing found» must not be remembered.
  final bool failed;

  /// Which source gave the text: 'lrclib', 'netease' or 'lyricsovh'.
  final String? source;
}

/// LRCLIB, then NetEase for the synchronised text, then lyrics.ovh for any text (D-111).
class LyricsChain {
  LyricsChain({required this.lrclib, this.netease, this.ovh});

  final LrclibClient lrclib;
  final NeteaseLyricsClient? netease;
  final LyricsOvhClient? ovh;

  static bool _has(String? s) => s != null && s.isNotEmpty;

  /// Rate limits and cancellation propagate; any other source error (LRCLIB included) is logged and reported as [LyricsChainResult.failed].
  Future<LyricsChainResult> find(
    Track t, {
    bool wantSynced = true,
    CancelToken? cancel,
  }) async {
    final c = cleanSearchQuery(t.title, t.artist ?? '');
    final sec = t.durationMs > 0 ? (t.durationMs / 1000).round() : null;
    var failed = false;
    Future<LyricsResult?> fallback(Future<LyricsResult?> Function() f) async {
      try {
        return await f();
      } on RateLimitedException {
        rethrow;
      } on DioException {
        rethrow;
      } catch (e, st) {
        AppLog.w('lyrics fallback failed', e, st);
        failed = true;
        return null;
      }
    }

    final lr = await fallback(
      () => lrclib.find(
        title: c.title,
        artist: c.artist,
        album: t.album,
        durationSec: sec,
        cancel: cancel,
        strict: true,
      ),
    );
    var plain = lr?.plain, synced = lr?.synced;
    String? source = lr == null || lr.isEmpty ? null : 'lrclib';
    final ne = netease;
    if (wantSynced && !_has(synced) && ne != null) {
      final r = await fallback(
        () => ne.find(
          title: c.title,
          artist: c.artist,
          durationSec: sec,
          cancel: cancel,
        ),
      );
      if (r != null) {
        synced = r.synced;
        source = 'netease';
      }
    }
    final o = ovh;
    if (!_has(plain) && !_has(synced) && o != null) {
      final r = await fallback(
        () => o.find(title: c.title, artist: extractPrimaryArtist(c.artist), cancel: cancel),
      );
      if (r != null) {
        plain = r.plain;
        source = 'lyricsovh';
      }
    }
    final out = LyricsResult(plain: plain, synced: synced);
    return out.isEmpty
        ? LyricsChainResult(failed: failed)
        : LyricsChainResult(lyrics: out, source: source);
  }
}
