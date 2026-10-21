import 'dart:convert';

import 'package:codecore/services/online/yt_dlp_process_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shape of `yt-dlp -J --flat-playlist` on a YouTube Music album page
/// (Stefano Rosso, 2026-10-21), cut to two tracks.
String _page({String title = 'Album - Stefano Rosso'}) => jsonEncode({
      'id': 'OLAK5uy_npsYLHQl5dQpvVBp6Z2GJUeA45XiSiJs0',
      'title': title,
      'uploader': null,
      '_type': 'playlist',
      'entries': [
        {
          'id': 'ePQ3h5SU2v8',
          'title': 'E Allora Senti Cosa Fò',
          'duration': 240,
          'channel': 'Stefano Rosso - Topic',
          'uploader': 'Stefano Rosso - Topic',
          'ie_key': 'Youtube',
          '_type': 'url',
          'url': 'https://music.youtube.com/watch?v=ePQ3h5SU2v8',
        },
        {
          'id': 'x2',
          'title': 'Una Storia Disonesta',
          'duration': 245,
          'channel': 'Stefano Rosso - Topic',
          'ie_key': 'Youtube',
        },
      ],
    });

void main() {
  test('a flat album page: the album from the page title, the artist from the Topic channel', () {
    final r = parseYtAlbumPage(_page());
    expect(r.map((t) => t.id), ['ePQ3h5SU2v8', 'x2']);
    expect(r.first.title, 'E Allora Senti Cosa Fò');
    expect(r.first.album, 'Stefano Rosso');
    expect(r.first.artists, ['Stefano Rosso']);
    expect(r.first.channel, 'Stefano Rosso - Topic');
    expect(r.first.duration, const Duration(seconds: 240));
  });

  test('EP and single pages too; full entries keep their own album', () {
    expect(parseYtAlbumPage(_page(title: 'EP - Bologna 77')).first.album, 'Bologna 77');
    final full = jsonEncode({
      'title': 'Album - X',
      'entries': [
        {'id': 'a', 'title': 'T', 'channel': 'C', 'album': 'Real', 'artists': ['A']},
      ],
    });
    final t = parseYtAlbumPage(full).single;
    expect(t.album, 'Real');
    expect(t.artists, ['A']);
  });
}
