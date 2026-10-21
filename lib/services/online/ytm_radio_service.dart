import '../../core/app_log.dart';
import 'innertube_client.dart';
import 'youtube_service.dart';
import 'ytm_radio_parser.dart';

/// The radio of a song: read directly from YouTube Music and, when that
/// answer cannot be read, from yt-dlp's mix for [cooldown] (as the search).
class YtmRadioService {
  YtmRadioService(
    this.client,
    this.fallbackSource, {
    this.cooldown = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final InnerTubeClient client;
  final YoutubeService fallbackSource;
  final Duration cooldown;
  final DateTime Function() _now;
  DateTime? _directOffUntil;

  /// The first page of the radio of [videoId], or the next one.
  /// [YtException] (network, rate limit) is not caught.
  Future<RadioPage> page(String videoId, {String? continuation}) async {
    final off = _directOffUntil;
    // The yt-dlp mix has one page only.
    if (continuation != null && off != null) return const RadioPage.empty();
    if (off == null || !_now().isBefore(off)) {
      try {
        return await client.radio(videoId, continuation: continuation);
      } on InnerTubeChanged catch (e) {
        AppLog.w('direct radio unreadable ($e): yt-dlp for ${cooldown.inMinutes} min');
        _directOffUntil = _now().add(cooldown);
        if (continuation != null) return const RadioPage.empty();
      }
    }
    return radioFallback(videoId);
  }

  /// yt-dlp's mix of [videoId]: 50 rows, no album.
  Future<RadioPage> radioFallback(String videoId) async {
    final listing = await fallbackSource.listPlaylist(
      'https://music.youtube.com/watch?v=$videoId&list=RDAMVM$videoId',
      limit: 50,
    );
    return RadioPage(radioFromListing(listing, seedId: videoId));
  }
}
