import 'package:dio/dio.dart';

import '../../core/app_log.dart';
import '../import/track_matcher.dart';
import 'http_client.dart';
import 'query_cleaner.dart';
import 'wikipedia_client.dart';

/// One recording of MusicBrainz (a performance of a song, with its credit).
class MbRecording {
  const MbRecording({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    this.length,
  });

  final String id, title, artistId, artistName;

  /// Milliseconds, when MusicBrainz knows them.
  final int? length;
}

/// MusicBrainz, the open music database: it says *which* song and *which*
/// artist a title is, with links to Wikidata, from where the exact Wikipedia
/// pages follow. No key; at most one request per second (the rules of the
/// service), so every call waits its turn.
class MusicBrainzClient {
  MusicBrainzClient(
    this._web, {
    Future<void> Function(Duration)? pause,
    DateTime Function()? now,
  })  : _pause = pause ?? Future<void>.delayed,
        _now = now ?? DateTime.now;

  final WebClient _web;
  final Future<void> Function(Duration) _pause;
  final DateTime Function() _now;

  static const _base = 'https://musicbrainz.org/ws/2';

  /// A little over one second between two requests.
  static const gap = Duration(milliseconds: 1100);
  DateTime? _last;

  Future<Map?> _get(String path, Map<String, String> query, CancelToken? cancel) async {
    // The service answers 503 now and then; a non-answer is tried once more.
    for (var attempt = 0; attempt < 2; attempt++) {
      final last = _last;
      if (last != null) {
        final wait = gap - _now().difference(last);
        if (!wait.isNegative && wait > Duration.zero) await _pause(wait);
      }
      _last = _now();
      final res = await _web.getJson('$_base/$path', query: {...query, 'fmt': 'json'}, cancel: cancel);
      if (res is Map) return res;
      if (attempt == 0) await _pause(const Duration(seconds: 2));
    }
    return null;
  }

  /// The recordings called [title] by [artist], best first: the ones whose
  /// title and credit are the same as asked (compared without accents and case).
  /// With [studioOnly] the search leaves out live recordings and bootlegs.
  Future<List<MbRecording>> recordings(String title, String artist,
      {bool studioOnly = false, CancelToken? cancel}) async {
    final t = title.replaceAll('"', ' ').trim();
    if (t.isEmpty) return const [];
    final by = artist.replaceAll('"', ' ').trim();
    final data = await _get(
      'recording',
      {
        'query': '${by.isEmpty ? 'recording:"$t"' : 'recording:"$t" AND artist:"$by"'}'
            '${studioOnly ? ' AND status:official AND primarytype:album AND NOT secondarytype:live' : ''}',
        'limit': '8',
      },
      cancel,
    );
    final list = data?['recordings'];
    if (list is! List) return const [];
    final wantTitle = matchKey(title);
    final wantArtist = matchKey(extractPrimaryArtist(artist));
    final out = <MbRecording>[];
    for (final r in list) {
      if (r is! Map || r['title'] is! String) continue;
      if (matchKey(r['title'] as String) != wantTitle) continue;
      final credit = r['artist-credit'];
      if (credit is! List) continue;
      for (final c in credit) {
        final a = c is Map ? c['artist'] : null;
        if (a is! Map || a['id'] is! String || a['name'] is! String) continue;
        // With an artist asked for, the credit has to be that artist.
        if (wantArtist.isNotEmpty && matchKey(a['name'] as String) != wantArtist) continue;
        out.add(MbRecording(
          id: r['id'] as String,
          title: r['title'] as String,
          artistId: a['id'] as String,
          artistName: a['name'] as String,
          length: r['length'] is num ? (r['length'] as num).toInt() : null,
        ));
        break;
      }
    }
    return out;
  }

  /// The genre of a recording of [title] by [artist] that lasts [durationMs]
  /// (within 3 s when MusicBrainz knows its length), null when none is sure.
  /// The recording's own genre counts with 2 votes or more; otherwise the
  /// artist's most voted one stands in. Capitalised like Wikipedia's titles.
  Future<String?> genreFor(String title, String artist, int durationMs,
      {CancelToken? cancel}) async {
    final found = await recordings(title, artist, studioOnly: true, cancel: cancel);
    final rec = found.where((r) {
      final len = r.length;
      return len == null || (len - durationMs).abs() <= 3000;
    }).firstOrNull;
    if (rec == null) return null;
    final own = _topGenre(await _get('recording/${rec.id}', {'inc': 'genres'}, cancel), 2);
    final name = own ?? _topGenre(await _get('artist/${rec.artistId}', {'inc': 'genres'}, cancel), 1);
    return name == null ? null : WikipediaClient.titleCase(name);
  }

  static String? _topGenre(Map? data, int minVotes) {
    final genres = data?['genres'];
    if (genres is! List) return null;
    String? best;
    var votes = minVotes - 1;
    for (final g in genres) {
      if (g is! Map || g['name'] is! String || g['count'] is! num) continue;
      if ((g['count'] as num) > votes) {
        best = g['name'] as String;
        votes = (g['count'] as num).toInt();
      }
    }
    return best;
  }

  /// The artist called [name], when MusicBrainz is sure (an exact name and a
  /// high score); null otherwise.
  Future<({String id, String name})?> artist(String name, {CancelToken? cancel}) async {
    final n = name.replaceAll('"', ' ').trim();
    if (n.isEmpty) return null;
    final data = await _get('artist', {'query': 'artist:"$n"', 'limit': '5'}, cancel);
    final list = data?['artists'];
    if (list is! List) return null;
    final want = matchKey(n);
    for (final a in list) {
      if (a is! Map || a['id'] is! String || a['name'] is! String) continue;
      final score = a['score'];
      if (matchKey(a['name'] as String) == want && (score is! num || score >= 90)) {
        return (id: a['id'] as String, name: a['name'] as String);
      }
    }
    return null;
  }

  /// The Wikidata item of the artist (`Q…`), or null.
  Future<String?> artistWikidata(String artistId, {CancelToken? cancel}) async {
    final data = await _get('artist/$artistId', {'inc': 'url-rels'}, cancel);
    return _wikidataOf(data);
  }

  /// The Wikidata item of the *song* a recording is a performance of, or null
  /// (many recordings have no work, and many works no page).
  Future<String?> songWikidata(String recordingId, {CancelToken? cancel}) async {
    final rec = await _get('recording/$recordingId', {'inc': 'work-rels'}, cancel);
    final rels = rec?['relations'];
    if (rels is! List) return null;
    for (final r in rels) {
      final work = r is Map ? r['work'] : null;
      if (work is! Map || work['id'] is! String) continue;
      final data = await _get('work/${work['id']}', {'inc': 'url-rels'}, cancel);
      final q = _wikidataOf(data);
      if (q != null) return q;
    }
    return null;
  }

  static final _qid = RegExp(r'/(Q\d+)$');

  static String? _wikidataOf(Map? data) {
    final rels = data?['relations'];
    if (rels is! List) return null;
    for (final r in rels) {
      if (r is! Map || r['type'] != 'wikidata') continue;
      final url = r['url'];
      final res = url is Map ? url['resource'] : null;
      final m = res is String ? _qid.firstMatch(res) : null;
      if (m != null) return m.group(1);
    }
    return null;
  }
}

/// Wikidata: from an item to the title of its Wikipedia page, in each language.
class WikidataClient {
  WikidataClient(this._web);

  final WebClient _web;

  /// For each item in [ids], its page title per language of [langs] (`it` →
  /// «Pink Floyd»); items or languages without a page are absent.
  Future<Map<String, Map<String, String>>> sitelinks(List<String> ids, List<String> langs,
      {CancelToken? cancel}) async {
    if (ids.isEmpty || langs.isEmpty) return const {};
    final data = await _web.getJson(
      'https://www.wikidata.org/w/api.php',
      query: {
        'action': 'wbgetentities',
        'ids': ids.join('|'),
        'props': 'sitelinks',
        'sitefilter': langs.map((l) => '${l}wiki').join('|'),
        'format': 'json',
      },
      cancel: cancel,
    );
    final entities = data is Map ? data['entities'] : null;
    if (entities is! Map) return const {};
    final out = <String, Map<String, String>>{};
    for (final e in entities.entries) {
      final links = e.value is Map ? (e.value as Map)['sitelinks'] : null;
      if (links is! Map) continue;
      final byLang = <String, String>{};
      for (final l in langs) {
        final t = links['${l}wiki'];
        if (t is Map && t['title'] is String) byLang[l] = t['title'] as String;
      }
      if (byLang.isNotEmpty) out['${e.key}'] = byLang;
    }
    if (out.isEmpty) AppLog.i('wikidata: no pages for $ids');
    return out;
  }
}
