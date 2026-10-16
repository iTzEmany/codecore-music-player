import 'package:dio/dio.dart';

import 'http_client.dart';
import 'query_cleaner.dart';

class ItunesMatch {
  const ItunesMatch({
    required this.title,
    required this.artist,
    this.album,
    this.year,
    this.genre,
    this.trackNumber,
    this.artworkUrl,
  });

  final String title, artist;
  final String? album, genre, artworkUrl;
  final int? year, trackNumber;
}

class ItunesAlbum {
  const ItunesAlbum({required this.name, required this.artist, this.artworkUrl});

  final String name, artist;
  final String? artworkUrl;
}

final _albumNoise = RegExp(
    r'\s*[\(\[][^\)\]]*(deluxe|bonus|remastered|expanded|anniversary)[^\)\]]*[\)\]]',
    caseSensitive: false);

class ItunesClient {
  /// [country] (ISO code, e.g. `IT`) picks the store: each one has its own
  /// catalogue, and the default (US) lacks much local music.
  ItunesClient(this._web, {this.country});

  final WebClient _web;
  final String? Function()? country;

  Map<String, String> _store() {
    final c = country?.call();
    return c == null || c.isEmpty ? const {} : {'country': c};
  }

  static const _endpoint = 'https://itunes.apple.com/search';

  List<String> buildQueries(String title, String artist) {
    final primary = extractPrimaryArtist(artist);
    final core = coreTitle(title);
    final out = <String>[];
    void add(String q) {
      final t = q.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }

    add('$artist $title');
    if (primary != artist) add('$primary $title');
    if (core != title) add('$artist $core');
    add('$primary $core');
    add(title);
    if (core != title) add(core);
    return out;
  }

  Future<ItunesMatch?> search(String title, String artist,
      {CancelToken? cancel}) async {
    for (final q in buildQueries(title, artist)) {
      final data = await _web.getJson(_endpoint,
          query: {
            'term': q,
            'media': 'music',
            'entity': 'song',
            'limit': '8',
            ..._store(),
          },
          cancel: cancel);
      final results = data is Map ? data['results'] : null;
      if (results is! List) continue;
      final best = _pickBest(results, title, artist);
      if (best != null) return best;
    }
    return null;
  }

  /// The album an `Album Name` + artist of a playlist file points to. The
  /// artist must match: a cover of the wrong record is worse than none.
  Future<ItunesAlbum?> searchAlbum(String album, String artist,
      {CancelToken? cancel}) async {
    final wantAlbum = _lc(album.replaceAll(_albumNoise, ''));
    final wantArtist = _lc(extractPrimaryArtist(artist));
    if (wantAlbum.isEmpty) return null;
    final data = await _web.getJson(_endpoint,
        query: {
          'term': '$artist $album'.trim(),
          'media': 'music',
          'entity': 'album',
          'limit': '6',
          ..._store(),
        },
        cancel: cancel);
    final results = data is Map ? data['results'] : null;
    if (results is! List) return null;
    ItunesAlbum? best;
    var bestScore = 0;
    for (final r in results) {
      if (r is! Map) continue;
      final name = _lc('${r['collectionName'] ?? ''}'.replaceAll(_albumNoise, ''));
      final by = _lc('${r['artistName'] ?? ''}');
      final albumScore = _score(name, wantAlbum, 12, 7);
      final artistScore = wantArtist.isEmpty ? 5 : _score(by, wantArtist, 10, 5);
      if (albumScore == 0 || artistScore == 0) continue;
      final art = r['artworkUrl100'] as String?;
      if (albumScore + artistScore > bestScore && art != null) {
        bestScore = albumScore + artistScore;
        best = ItunesAlbum(
          name: '${r['collectionName']}',
          artist: '${r['artistName']}',
          artworkUrl: art.replaceFirst('100x100bb', '600x600bb'),
        );
      }
    }
    return best;
  }

  ItunesMatch? _pickBest(List<dynamic> results, String title, String artist) {
    final wantTitle = _lc(title), wantTitleCore = _lc(coreTitle(title));
    final wantArtist = _lc(artist);
    final artistKnown = wantArtist.isNotEmpty;
    ItunesMatch? best;
    var bestScore = -1;
    for (final r in results) {
      if (r is! Map) continue;
      final name = _lc('${r['trackName'] ?? ''}');
      final by = _lc('${r['artistName'] ?? ''}');
      if (name.isEmpty) continue;
      var titleScore = _score(name, wantTitle, 12, 7);
      final coreScore = _score(name, wantTitleCore, 12, 7);
      if (coreScore > titleScore) titleScore = coreScore;
      final artistScore = artistKnown ? _score(by, wantArtist, 10, 5) : 0;
      if (titleScore == 0) continue;
      if (artistKnown && artistScore == 0) continue;
      if (!artistKnown &&
          (titleScore < 12 || wantTitle.split(' ').length < 2)) {
        continue;
      }
      final total = titleScore + artistScore;
      if (total > bestScore) {
        bestScore = total;
        best = _toMatch(r);
      }
    }
    return best;
  }

  int _score(String a, String b, int exact, int partial) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return exact;
    if (a.contains(b) || b.contains(a)) return partial;
    return 0;
  }

  String _lc(String s) => s.toLowerCase().trim();

  ItunesMatch _toMatch(Map<dynamic, dynamic> r) {
    final date = '${r['releaseDate'] ?? ''}';
    final art = r['artworkUrl100'] as String?;
    final album = r['collectionName'] as String?;
    return ItunesMatch(
      title: '${r['trackName']}',
      artist: '${r['artistName']}',
      album: album?.replaceAll(_albumNoise, '').trim(),
      year: date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null,
      genre: r['primaryGenreName'] as String?,
      trackNumber: r['trackNumber'] as int?,
      artworkUrl: art?.replaceFirst('100x100bb', '600x600bb'),
    );
  }
}
