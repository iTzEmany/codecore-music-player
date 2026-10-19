import 'package:dio/dio.dart';

import '../import/track_matcher.dart';
import 'http_client.dart';
import 'query_cleaner.dart';

class Curiosity {
  const Curiosity(this.text, this.source, this.lang);

  final String text;
  final Uri source;
  final String lang;
}

class WikipediaClient {
  WikipediaClient(this._web);

  final WebClient _web;

  /// The article about the song itself. A page about the artist (or about
  /// anything else the search happens to rank first) is never returned. A title
  /// with a tail («Song - Remastered 2011», «Song - Live at …») is tried whole
  /// first and then without the tail.
  Future<Curiosity?> findSong(String title, String artist, String lang,
      {CancelToken? cancel}) async {
    final variants = {
      title.trim(),
      title.split(RegExp(r'\s+[-–—]\s+')).first.trim(),
    }.where((v) => v.isNotEmpty);
    final by = matchKey(extractPrimaryArtist(artist));
    for (final name in variants) {
      final song = matchKey(name);
      if (song.isEmpty) continue;
      final found = await _firstIn(lang, cancel, (l) {
        // OR groups: every word of an AND list would have to be on the page.
        final words = l == 'en' ? '(song OR single)' : '(canzone OR singolo OR brano OR song)';
        return _Query(
          '"$name" $artist $words',
          (page, extract) {
            final pageName = matchKey(_withoutQualifier(page));
            if (pageName == by && pageName != song) return false; // the artist's page
            if (pageName == song) return true;
            // Named differently: the lead must name both the song and the artist.
            final head = matchKey(extract.substring(0, extract.length.clamp(0, 400)));
            return by.isNotEmpty && head.contains(song) && head.contains(by);
          },
        );
      });
      if (found != null) return found;
    }
    return null;
  }

  /// The article about the artist or band.
  Future<Curiosity?> findArtist(String artist, String lang,
      {CancelToken? cancel}) async {
    final name = extractPrimaryArtist(artist).trim();
    final key = matchKey(name);
    if (key.isEmpty) return null;
    return _firstIn(lang, cancel, (l) {
      return _Query(
        '"$name" (cantante OR gruppo OR band OR singer OR musician OR rapper)',
        (page, extract) => matchKey(_withoutQualifier(page)) == key,
      );
    });
  }

  /// Kept for the callers that want the song's article.
  Future<Curiosity?> find(String title, String artist, String lang,
          {CancelToken? cancel}) =>
      findSong(title, artist, lang, cancel: cancel);

  Future<Curiosity?> _firstIn(
      String lang, CancelToken? cancel, _Query Function(String lang) query) async {
    final langs = lang == 'en' ? ['en'] : [lang, 'en'];
    for (final l in langs) {
      final q = query(l);
      final c = await _findIn(l, q.search, q.accept, cancel);
      if (c != null) return c;
    }
    return null;
  }

  /// «Title (song)», «Title (Band song)» → «Title».
  static String _withoutQualifier(String page) =>
      page.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '');

  /// One request per language: the search and the intro of every hit come back
  /// together (`generator=search` + `prop=extracts`), so a lookup stays within
  /// a few requests; Wikipedia answers bursts with HTTP 429.
  Future<Curiosity?> _findIn(String lang, String search,
      bool Function(String page, String extract) accept, CancelToken? cancel) async {
    final api = 'https://$lang.wikipedia.org/w/api.php';
    final found = await _web.getJson(api,
        query: {
          'action': 'query',
          'generator': 'search',
          'gsrsearch': search,
          'gsrlimit': '5',
          'prop': 'extracts',
          'exintro': '1',
          'explaintext': '1',
          'exlimit': '5',
          'redirects': '1',
          'format': 'json',
        },
        cancel: cancel);
    final pages = (found is Map ? found['query'] : null) is Map
        ? ((found as Map)['query'] as Map)['pages']
        : null;
    if (pages is! Map) return null;
    // Back in the order of the search ranking.
    final ranked = [
      for (final v in pages.values)
        if (v is Map && v['title'] is String) v,
    ]..sort((x, y) => ((x['index'] as num?) ?? 0).compareTo((y['index'] as num?) ?? 0));
    for (final h in ranked) {
      final page = h['title'] as String;
      final extract = h['extract'] as String?;
      if (extract == null) continue;
      final lower = extract.toLowerCase();
      if (extract.length < 80 ||
          lower.contains('disambigua') ||
          lower.contains('may refer to')) {
        continue;
      }
      if (!accept(page, extract)) continue;
      final url = Uri.https(
          '$lang.wikipedia.org', '/wiki/${page.replaceAll(' ', '_')}');
      return Curiosity(_truncate(extract.trim()), url, lang);
    }
    return null;
  }

  /// Long enough to read as an article's opening, short enough to store.
  String _truncate(String s) {
    if (s.length <= 1500) return s;
    final cut = s.substring(0, 1500);
    final end = cut.lastIndexOf(RegExp(r'[.!?]\s'));
    return end > 200 ? cut.substring(0, end + 1) : cut;
  }
}

class _Query {
  const _Query(this.search, this.accept);

  final String search;
  final bool Function(String page, String extract) accept;
}
