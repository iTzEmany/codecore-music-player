import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/ytm_album_parser.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:flutter_test/flutter_test.dart';

Map fixture(String name) =>
    jsonDecode(File('test/fixtures/innertube/$name.json').readAsStringSync()) as Map;

void main() {
  test('an album page lists its tracks in order with the album artist', () {
    final album = parseAlbumPage(fixture('ytm_album_page'), 'MPREb_tc3z4MYeOpY');
    expect(album.title, 'The Wall');
    expect(album.year, '1979');
    expect(album.kindLabel, 'Album');
    expect(album.artist?.name, 'Pink Floyd');
    expect(album.artist?.id, 'UCO6LS_5W7vqG9mALDNzSFug');
    expect(album.coverUrl, contains('=w544-h544'));
    expect(album.tracks, hasLength(26));
    expect([for (final t in album.tracks) t.number], List.generate(26, (i) => i + 1));
    final first = album.tracks.first.result;
    expect(first.title, 'In the Flesh?');
    expect(first.duration, const Duration(minutes: 3, seconds: 19));
    expect(first.artists, ['Pink Floyd']);
    expect(first.artistIds, ['UCO6LS_5W7vqG9mALDNzSFug']);
    expect(first.album, 'The Wall');
    expect(first.albumId, 'MPREb_tc3z4MYeOpY');
  });

  test('a page without the album header is a changed format', () {
    final broken = jsonEncode(fixture('ytm_album_page'))
        .replaceFirst('musicResponsiveHeaderRenderer', 'otherHeader');
    expect(() => parseAlbumPage(jsonDecode(broken) as Map, 'x'),
        throwsA(isA<InnerTubeChanged>()));
  });

  test('the full list of songs has lengths', () {
    final songs = parseSongList(fixture('ytm_artist_songs'));
    expect(songs, hasLength(10));
    expect(songs.every((s) => s.duration != null), isTrue);
    expect(songs.first.title, 'Wish You Were Here');
  });

  test('the discography lists the releases', () {
    final list = parseDiscography(fixture('ytm_discography'));
    expect(list, hasLength(6));
    expect(list.every((r) => r.browseId.startsWith('MPREb_')), isTrue);
    expect(list.first.title, '8-Tracks');
  });

  test('an album survives a cached round trip', () {
    final album = parseAlbumPage(fixture('ytm_album_page'), 'MPREb_tc3z4MYeOpY');
    final again = YtmAlbum.fromJson(jsonDecode(jsonEncode(album.toJson())))!;
    expect(again.tracks, hasLength(26));
    expect(again.tracks[3].number, 4);
    expect(again.artist?.id, album.artist?.id);
  });
}
