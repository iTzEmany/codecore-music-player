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

// The names of each list, normalised once per list (a new list comes only
// when the library changes), not again at every key typed.
final _artistNames = Expando<List<String>>();
final _albumNames = Expando<List<(String, String)>>();
final _playlistNames = Expando<List<String>>();

List<String> _normalArtists(List<ArtistSummary> list) =>
    _artistNames[list] ??= [for (final a in list) normalize(a.name ?? '')];

List<(String, String)> _normalAlbums(List<AlbumSummary> list) =>
    _albumNames[list] ??= [
      for (final a in list)
        (normalize(a.title ?? ''), normalize('${a.artist ?? ''} ${a.year ?? ''}')),
    ];

List<String> _normalPlaylists(List<PlaylistSummary> list) =>
    _playlistNames[list] ??= [for (final p in list) normalize(p.playlist.name)];

bool _hasAll(String haystack, List<String> words) => words.every(haystack.contains);

/// [items] kept in order, those whose [name] equals the text first, then those
/// that start with it, then the rest.
List<T> _ranked<T>(List<(T, String)> items, String needle) {
  int tier(String n) => n == needle ? 0 : (n.startsWith(needle) ? 1 : 2);
  final sorted = [...items]..sort((a, b) => tier(a.$2).compareTo(tier(b.$2)));
  return [for (final i in sorted) i.$1];
}

/// Filters the (small) artist / album / playlist lists in memory (every word
/// of the text must be in the name, accents and case ignored); [tracks] are
/// the matches of the same text. The main result is the artist whose name
/// starts with the text, otherwise the first album, otherwise the first track.
///
/// When the text uses operators (`artista:x anno:1990..`), [tracks] are the
/// matches of the rules and the other sections only look at its plain words;
/// with no plain word they stay empty. With [quickFilter] («Preferiti»,
/// «Recenti») artists and albums are only those of [tracks] and playlists are
/// left out.
LibrarySearchResults searchLibrary({
  required String text,
  required List<Track> tracks,
  required List<ArtistSummary> artists,
  required List<AlbumSummary> albums,
  required List<PlaylistSummary> playlists,
  bool quickFilter = false,
  int trackLimit = 4,
  int sectionLimit = 12,
}) {
  final withRules = hasOperators(text);
  final needle = normalize((withRules ? freeTextOf(text) : text).trim());
  if (needle.isEmpty) {
    if (!withRules && !quickFilter) return const LibrarySearchResults();
    return LibrarySearchResults(
      tracks: tracks.take(trackLimit).toList(),
      trackTotal: tracks.length,
      main: tracks.firstOrNull,
    );
  }
  final words = needle.split(' ');
  final artistNames = _normalArtists(artists);
  final albumNames = _normalAlbums(albums);
  final playlistNames = _normalPlaylists(playlists);
  final artistKeys = quickFilter
      ? {for (final t in tracks) (t.artist ?? '').trim().toLowerCase()}
      : null;
  final albumKeys = quickFilter ? {for (final t in tracks) t.albumKey} : null;
  final matchedArtists = _ranked([
    for (var i = 0; i < artists.length; i++)
      if (artists[i].key.isNotEmpty &&
          artists[i].name != null &&
          (artistKeys == null || artistKeys.contains(artists[i].key)) &&
          _hasAll(artistNames[i], words))
        (artists[i], artistNames[i]),
  ], needle);
  final matchedAlbums = _ranked([
    for (var i = 0; i < albums.length; i++)
      if ((albumKeys == null || albumKeys.contains(albums[i].albumKey)) &&
          _hasAll('${albumNames[i].$1} ${albumNames[i].$2}', words))
        (albums[i], albumNames[i].$1),
  ], needle);
  final matchedPlaylists = quickFilter
      ? const <PlaylistSummary>[]
      : [
          for (var i = 0; i < playlists.length; i++)
            if (_hasAll(playlistNames[i], words)) playlists[i],
        ];
  Object? main;
  final starts = [
    for (var i = 0; i < artists.length; i++)
      if (artists[i].key.isNotEmpty && artists[i].name != null && artistNames[i].startsWith(needle))
        if (matchedArtists.contains(artists[i])) artists[i],
  ].firstOrNull;
  if (starts != null) {
    main = starts;
  } else if (tracks.isNotEmpty && normalize(tracks.first.title) == needle) {
    main = tracks.first;
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
