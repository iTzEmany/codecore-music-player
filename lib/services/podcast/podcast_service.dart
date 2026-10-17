import '../../core/app_log.dart';
import '../../data/repositories/podcast_repository.dart';
import '../online/http_client.dart';
import 'podcast_models.dart';

/// Used until the RSS reader is wired in (it needs the `xml` package): every
/// attempt to read a feed says so instead of pretending.
Future<PodcastFeed> unavailableFeedParser(String xml) =>
    Future.error(const PodcastException(PodcastErrorKind.parserMissing));

/// A podcast is worth refreshing when it was last checked this long ago.
const staleAfter = Duration(hours: 6);

/// What a refresh of every podcast did.
class RefreshReport {
  RefreshReport();

  /// New episodes per podcast id.
  final added = <int, int>{};

  /// Podcasts that could not be refreshed, with the reason.
  final failed = <int, PodcastException>{};

  int get totalAdded => added.values.fold(0, (n, v) => n + v);
}

/// Subscribing, refreshing and searching. The network starts only from here,
/// and only when the user asks (or opens a stale podcast): never on its own.
class PodcastService {
  PodcastService({
    required this.repo,
    required this.fetch,
    required this.parse,
    required this.web,
    this.saveCover,
    RateLimiter? searchLimiter,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        _limiter = searchLimiter ?? RateLimiter(minGap: const Duration(seconds: 1));

  final PodcastRepository repo;
  final FeedFetcher fetch;
  final FeedParser parse;
  final WebClient web;

  /// Downloads and stores the cover at [imageUrl]; returns its cover key.
  final Future<String?> Function(int podcastId, String imageUrl)? saveCover;
  final RateLimiter _limiter;
  final DateTime Function() _now;

  static const _search = 'https://itunes.apple.com/search';

  int get _nowMs => _now().millisecondsSinceEpoch;

  /// An address typed or pasted by the user: trimmed, `feed:` read as https, a
  /// missing scheme as https. Anything that is not http(s) is refused.
  static String normalizeUrl(String input) {
    var t = input.trim();
    if (t.toLowerCase().startsWith('feed://')) {
      t = 'https://${t.substring(7)}';
    } else if (t.toLowerCase().startsWith('feed:')) {
      t = t.substring(5);
    }
    if (!t.contains('://') && t.contains('.') && !t.contains(' ')) t = 'https://$t';
    final u = Uri.tryParse(t);
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) {
      throw PodcastException(PodcastErrorKind.invalidUrl, input);
    }
    return u.toString();
  }

  Future<PodcastFeed> _read(String url) async {
    final String text;
    try {
      text = await fetch(url);
    } on PodcastException {
      rethrow;
    } on Object catch (e, st) {
      AppLog.w('feed fetch failed: $url', e, st);
      throw PodcastException(PodcastErrorKind.network, '$e');
    }
    if (text.length > maxFeedBytes) {
      throw const PodcastException(PodcastErrorKind.tooLarge);
    }
    try {
      return await parse(text);
    } on PodcastException {
      rethrow;
    } on FormatException catch (e) {
      throw PodcastException(PodcastErrorKind.notFeed, e.message);
    }
  }

  /// Subscribes to the feed at [url]. Returns the podcast's id; subscribing
  /// again to the same address just refreshes it.
  Future<int> subscribeFromUrl(String url) async {
    final feedUrl = normalizeUrl(url);
    final feed = await _read(feedUrl);
    final id = await repo.subscribe(feedUrl, feed, now: _nowMs);
    await _cover(id, feed.imageUrl);
    return id;
  }

  Future<void> _cover(int id, String? imageUrl) async {
    final save = saveCover;
    if (save == null || imageUrl == null) return;
    final podcast = await repo.byId(id);
    if (podcast == null || podcast.coverKey != null) return;
    try {
      final key = await save(id, imageUrl);
      if (key != null) await repo.setCoverKey(id, key);
    } on Object catch (e, st) {
      // A missing cover must never fail a subscription.
      AppLog.w('podcast cover failed: $imageUrl', e, st);
    }
  }

  /// Reads the feed again and adds the new episodes. Returns how many.
  Future<int> refresh(int podcastId) async {
    final podcast = await repo.byId(podcastId);
    if (podcast == null) return 0;
    final feed = await _read(podcast.feedUrl);
    final added = await repo.upsertEpisodes(podcastId, feed.episodes);
    await repo.markChecked(podcastId, _nowMs);
    await _cover(podcastId, feed.imageUrl ?? podcast.imageUrl);
    return added;
  }

  /// [refresh] only if the podcast was never checked or not for [staleAfter].
  /// Returns the new episodes, or null when nothing was asked of the network.
  Future<int?> refreshIfStale(int podcastId) async {
    final podcast = await repo.byId(podcastId);
    if (podcast == null) return null;
    final last = podcast.lastCheckedAt;
    if (last != null && _nowMs - last < staleAfter.inMilliseconds) return null;
    return refresh(podcastId);
  }

  /// Every podcast, one after the other; a failure does not stop the rest.
  Future<RefreshReport> refreshAll() async {
    final report = RefreshReport();
    for (final p in await repo.all()) {
      try {
        report.added[p.id] = await refresh(p.id);
      } on PodcastException catch (e) {
        report.failed[p.id] = e;
      }
    }
    return report;
  }

  /// The public podcast directory (iTunes Search API, no key). Results without
  /// a feed address are dropped.
  Future<List<PodcastSearchHit>> search(String term, {int limit = 10}) async {
    final t = term.trim();
    if (t.isEmpty) return const [];
    await _limiter.wait();
    final json = await web.getJson(_search, query: {
      'media': 'podcast',
      'term': t,
      'limit': '$limit',
    });
    if (json is! Map || json['results'] is! List) {
      throw const PodcastException(PodcastErrorKind.network, 'search');
    }
    final out = <PodcastSearchHit>[];
    for (final r in json['results'] as List) {
      if (r is! Map) continue;
      final feed = r['feedUrl'];
      final name = r['collectionName'] ?? r['trackName'];
      if (feed is! String || feed.isEmpty || name is! String) continue;
      final count = r['trackCount'];
      out.add(PodcastSearchHit(
        name: name,
        feedUrl: feed,
        author: r['artistName'] as String?,
        artworkUrl: (r['artworkUrl600'] ?? r['artworkUrl100']) as String?,
        episodeCount: count is int ? count : null,
      ));
    }
    return out;
  }
}
