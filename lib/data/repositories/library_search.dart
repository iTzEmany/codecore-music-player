import '../../core/text_utils.dart';
import '../../services/library/rules/rule_parser.dart';
import '../db/app_database.dart';
import 'library_queries.dart';
import 'playlist_repository.dart';

/// What the unified Library search shows for one text.
class LibrarySearchResults {
  const LibrarySearchResults({
    this.tracks = const [],
    this.trackTotal = 0,
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
    this.main,
  });

  /// First few matching tracks (see `trackLimit` of [searchLibrary]).
  final List<Track> tracks;
  final int trackTotal;
  final List<ArtistSummary> artists;
  final List<AlbumSummary> albums;
  final List<PlaylistSummary> playlists;

  /// An [ArtistSummary], [AlbumSummary] or [Track].
  final Object? main;

  bool get isEmpty =>
      tracks.isEmpty && artists.isEmpty && albums.isEmpty && playlists.isEmpty;
}

bool _matches(String? value, String needle) =>
    value != null && normalize(value).contains(needle);

/// Filters the (small) artist / album / playlist lists in memory; [tracks]
/// are the SQL matches of the same text. The main result is the artist whose
/// name starts with the text, otherwise the first album, otherwise the first
/// track.
///
/// When the text uses operators (`artista:x anno:1990..`), [tracks] are the
/// matches of the rules and the other sections only look at its plain words;
/// with no plain word they stay empty.
LibrarySearchResults searchLibrary({
  required String text,
  required List<Track> tracks,
  required List<ArtistSummary> artists,
  required List<AlbumSummary> albums,
  required List<PlaylistSummary> playlists,
  int trackLimit = 4,
  int sectionLimit = 12,
}) {
  final withRules = hasOperators(text);
  final needle = normalize((withRules ? freeTextOf(text) : text).trim());
  if (needle.isEmpty) {
    if (!withRules) return const LibrarySearchResults();
    return LibrarySearchResults(
      tracks: tracks.take(trackLimit).toList(),
      trackTotal: tracks.length,
      main: tracks.firstOrNull,
    );
  }
  final matchedArtists = [
    for (final a in artists)
      if (a.key.isNotEmpty && _matches(a.name, needle)) a,
  ];
  final matchedAlbums = [
    for (final a in albums)
      if (_matches(a.title, needle) || _matches(a.artist, needle)) a,
  ];
  final matchedPlaylists = [
    for (final p in playlists)
      if (_matches(p.playlist.name, needle)) p,
  ];
  Object? main;
  final starts = matchedArtists
      .where((a) => normalize(a.name ?? '').startsWith(needle))
      .firstOrNull;
  if (starts != null) {
    main = starts;
  } else if (matchedAlbums.isNotEmpty) {
    main = matchedAlbums.first;
  } else if (tracks.isNotEmpty) {
    main = tracks.first;
  }
  return LibrarySearchResults(
    tracks: tracks.take(trackLimit).toList(),
    trackTotal: tracks.length,
    artists: matchedArtists.take(sectionLimit).toList(),
    albums: matchedAlbums.take(sectionLimit).toList(),
    playlists: matchedPlaylists.take(sectionLimit).toList(),
    main: main,
  );
}
