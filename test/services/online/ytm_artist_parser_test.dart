import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_artist_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real answers (2026-10-22) trimmed of tracking data, carousels cut to 4.
Map fixture(String name) =>
    jsonDecode(File('test/fixtures/innertube/$name.json').readAsStringSync()) as Map;

const pinkFloyd = 'UCO6LS_5W7vqG9mALDNzSFug';

void main() {
  topCardTests();
  test('the card of an artist gives its id, name, photo and audience', () {
    final ref = parseTopArtistCard(fixture('ytm_top_artist_card'))!;
    expect(ref.id, pinkFloyd);
    expect(ref.name, 'PINK FLOYD');
    expect(ref.audience, '25.9M monthly audience');
    expect(ref.thumbnailUrl, contains('=w120-h120'));
  });

  test('the card of a song is not an artist', () {
    expect(parseTopArtistCard(fixture('ytm_top_song_card')), isNull);
    expect(parseTopArtistCard(fixture('ytm_empty')), isNull);
  });

  test('the artist search lists the artists in order, with photo and audience', () {
    final list = parseArtistSearch(fixture('ytm_artists'));
    expect(list, hasLength(5));
    expect(list.first.id, pinkFloyd);
    expect(list.first.audience, '25.9M monthly audience');
    expect(list.every((a) => a.id.startsWith('UC') && a.thumbnailUrl != null), isTrue);
  });

  test('the artist page is read by item kind: songs, releases, similar artists', () {
    final page = parseArtistPage(fixture('ytm_artist_page'), pinkFloyd);
    expect(page.ref.name, 'PINK FLOYD');
    expect(page.ref.audience, '25.9M monthly audience');
    expect(page.description, startsWith('Pink Floyd, one of the most'));
    expect(page.radio?.playlistId, startsWith('RDEM'));

    final songs = page.shelves.whereType<YtmSongShelf>().single;
    expect(songs.songs, hasLength(5));
    expect(songs.songs.first.title, 'Wish You Were Here');
    expect(songs.songs.first.artistIds, [pinkFloyd]);
    expect(songs.songs.first.albumId, startsWith('MPREb_'));
    expect(songs.songs.first.duration, isNull);
    expect(songs.allSongs?.browseId, startsWith('VLOLAK5uy_'));
    expect(songs.allSongs?.params, isNotEmpty);

    final releases = page.shelves.whereType<YtmReleaseShelf>().toList();
    expect(releases, hasLength(2));
    expect(releases.every((s) => s.releases.every((r) => r.browseId.startsWith('MPREb_'))), isTrue);
    expect(releases.first.more?.browseId, startsWith('MPAD'));

    final similar = page.shelves.whereType<YtmArtistShelf>().single;
    expect(similar.artists, hasLength(10));
    // Videos, podcasts, live performances, featured-on and playlists are left out.
    expect(page.shelves, hasLength(4));
  });

  test('the Italian page has the same sections with the titles YouTube translated', () {
    final page = parseArtistPage(fixture('ytm_artist_page_it'), 'UCmUrlA_x25EXhvlsRHmC3bw');
    expect(page.shelves.map((s) => s.runtimeType), [
      YtmSongShelf,
      YtmReleaseShelf,
      YtmReleaseShelf,
      YtmArtistShelf,
    ]);
    expect(page.shelves.map((s) => s.title), contains('Singoli ed EP'));
    expect(page.ref.audience, contains('ascoltatori mensili'));
  });

  test('an artist with only singles has no album shelf and no description', () {
    final page = parseArtistPage(fixture('ytm_artist_page_sparse'), 'x');
    final releases = page.shelves.whereType<YtmReleaseShelf>().toList();
    expect(releases, hasLength(1));
    expect(releases.single.title, 'Singles & EPs');
    expect(page.description, isNull);
  });

  test('an unknown id is not found, a renamed container is a changed format', () {
    expect(() => parseArtistPage(fixture('ytm_artist_missing'), 'x'),
        throwsA(isA<ArtistNotFound>()));
    final renamed = jsonEncode(fixture('ytm_artist_page'))
        .replaceFirst('singleColumnBrowseResultsRenderer', 'otherRenderer');
    expect(() => parseArtistPage(jsonDecode(renamed) as Map, pinkFloyd),
        throwsA(isA<InnerTubeChanged>()));
  });

  test('the artist page survives a cached round trip', () {
    final page = parseArtistPage(fixture('ytm_artist_page'), pinkFloyd);
    final again = YtmArtistPage.fromJson(jsonDecode(jsonEncode(page.toJson())))!;
    expect(jsonEncode(again.toJson()), jsonEncode(page.toJson()));
    expect(again.shelves.map((s) => s.runtimeType), page.shelves.map((s) => s.runtimeType));
  });
}

void topCardTests() {
  test('the top card is read as an artist, an album, a song or a video', () {
    final artist = parseTopCard(fixture('ytm_top_artist_card')) as TopArtist;
    expect(artist.artist.id, pinkFloyd);

    final album = parseTopCard(fixture('ytm_top_album_card')) as TopAlbum;
    expect(album.release.browseId, startsWith('MPREb_'));
    expect(album.release.title, 'The Wall');
    expect(album.release.subtitle, 'Album • 1979');
    expect(album.artist?.id, pinkFloyd);

    final song = parseTopCard(fixture('ytm_top_song_card')) as TopSong;
    expect(song.videoId, 'cfWXEgEEurg');

    final video = parseTopCard(fixture('ytm_top_video_card')) as TopVideo;
    expect(video.videoId, 'fJ9rUzIMcZQ');
    expect(video.title, startsWith('Bohemian Rhapsody'));
  });

  test('no card, no top card', () {
    expect(parseTopCard(fixture('ytm_empty')), isNull);
    expect(parseTopArtistCard(fixture('ytm_top_album_card')), isNull);
  });
}
