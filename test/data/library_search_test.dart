import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/data/repositories/library_search.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Track track(int id, String title) => Track(
      id: id,
      path: '/$id',
      title: title,
      albumKey: 'k',
      format: 'mp3',
      sizeBytes: 1,
      mtimeMs: 1,
      addedAt: 1,
      durationMs: 1000,
      playCount: 0,
      isFavorite: false,
      missing: false,
      enrichStatus: 0,
      hasCover: false,
      userEdited: false,
    );

AlbumSummary album(String t, String artist) => AlbumSummary(
    albumKey: t,
    title: t,
    artist: artist,
    variousArtists: false,
    trackCount: 1,
    durationMs: 1,
    year: null,
    coverKey: null);

ArtistSummary artist(String n) =>
    ArtistSummary(key: n.toLowerCase(), name: n, trackCount: 2, albumCount: 1);

void main() {
  final artists = [artist('Queen'), artist('Mina'), artist('Blue Öyster')];
  final albums = [album('A Night At The Opera', 'Queen'), album('Queenie', 'X')];
  final playlists = [
    PlaylistSummary(Playlist(id: 1, name: 'Queen e amici', createdAt: 0), 3)
  ];

  test('artist whose name starts with the text is the main result', () {
    final r = searchLibrary(
      text: 'que',
      tracks: [track(1, 'Bohemian Rhapsody')],
      artists: artists,
      albums: albums,
      playlists: playlists,
    );
    expect(r.main, isA<ArtistSummary>());
    expect((r.main! as ArtistSummary).name, 'Queen');
    expect(r.albums.length, 2);
    expect(r.playlists.single.playlist.name, 'Queen e amici');
  });

  test('without a matching artist the first album wins, then the first track',
      () {
    final r1 = searchLibrary(
        text: 'night',
        tracks: const [],
        artists: artists,
        albums: albums,
        playlists: playlists);
    expect(r1.main, isA<AlbumSummary>());
    final r2 = searchLibrary(
        text: 'rhapsody',
        tracks: [track(1, 'Bohemian Rhapsody')],
        artists: artists,
        albums: albums,
        playlists: playlists);
    expect(r2.main, isA<Track>());
  });

  test('diacritics and case are ignored; tracks limited to 4 with a total',
      () {
    final r = searchLibrary(
      text: 'OYSTER',
      tracks: [for (var i = 0; i < 6; i++) track(i, 't$i')],
      artists: artists,
      albums: albums,
      playlists: playlists,
    );
    expect(r.artists.single.name, 'Blue Öyster');
    expect(r.tracks.length, 4);
    expect(r.trackTotal, 6);
  });

  test('blank text gives nothing', () {
    final r = searchLibrary(
        text: '  ',
        tracks: [track(1, 'x')],
        artists: artists,
        albums: albums,
        playlists: playlists);
    expect(r.isEmpty, isTrue);
    expect(r.main, isNull);
  });
}
