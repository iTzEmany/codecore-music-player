import 'package:dio/dio.dart';

import 'http_client.dart';

class Curiosity {
  const Curiosity(this.text, this.source, this.lang);

  final String text;
  final Uri source;
  final String lang;
}

class WikipediaClient {
  WikipediaClient(this._web);

  final WebClient _web;

  Future<Curiosity?> find(String title, String artist, String lang,
      {CancelToken? cancel}) async {
    final langs = lang == 'en' ? ['en'] : [lang, 'en'];
    for (final l in langs) {
      final c = await _findIn(l, title, artist, cancel);
      if (c != null) return c;
    }
    return null;
  }

  Future<Curiosity?> _findIn(
      String lang, String title, String artist, CancelToken? cancel) async {
    final api = 'https://$lang.wikipedia.org/w/api.php';
    final word = lang == 'en' ? 'song' : 'canzone';
    final search = await _web.getJson(api,
        query: {
          'action': 'query',
          'list': 'search',
          'srsearch': '$title $artist $word|song',
          'format': 'json',
          'srlimit': '3',
        },
        cancel: cancel);
    final hits = (search is Map ? search['query'] : null) is Map
        ? ((search as Map)['query'] as Map)['search']
        : null;
    if (hits is! List) return null;
    for (final h in hits) {
      final page = h is Map ? h['title'] as String? : null;
      if (page == null) continue;
      final ex = await _web.getJson(api,
          query: {
            'action': 'query',
            'prop': 'extracts',
            'explaintext': '1',
            'exintro': '1',
            'redirects': '1',
            'titles': page,
            'format': 'json',
          },
          cancel: cancel);
      final pages = (ex is Map ? ex['query'] : null) is Map
          ? ((ex as Map)['query'] as Map)['pages']
          : null;
      if (pages is! Map || pages.isEmpty) continue;
      final extract = (pages.values.first as Map)['extract'] as String?;
      if (extract == null) continue;
      final lower = extract.toLowerCase();
      if (extract.length < 80 ||
          lower.contains('disambigua') ||
          lower.contains('may refer to')) {
        continue;
      }
      final url = Uri.https(
          '$lang.wikipedia.org', '/wiki/${page.replaceAll(' ', '_')}');
      return Curiosity(_truncate(extract.trim()), url, lang);
    }
    return null;
  }

  String _truncate(String s) {
    if (s.length <= 1000) return s;
    final cut = s.substring(0, 1000);
    final end = cut.lastIndexOf(RegExp(r'[.!?]\s'));
    return end > 200 ? cut.substring(0, end + 1) : cut;
  }
}
