import '../../data/db/app_database.dart';
import '../../data/repositories/library_queries.dart';
import '../audio/online_entries.dart' show isOnlineId;
import '../../data/repositories/track_kinds.dart';
import 'query_cleaner.dart';
import 'youtube_service.dart';
import 'ytm_artist.dart';
import 'ytm_artist_resolver.dart';

/// A credited artist: [sep] is the original text that follows the name
/// ('' for the last one), [ytmId] the YouTube Music page when known.
class ArtistName {
  const ArtistName(this.name, {this.ytmId, this.sep = ''});

  final String name;
  final String? ytmId;
  final String sep;
}

/// The artists of a library track, with their original separators.
List<ArtistName> libraryArtists(Track t) => [
      for (final a in splitArtists(t.artist ?? ''))
        ArtistName(a.name, sep: a.sep),
    ];

/// The artists credited on an online result; [ytmId] only where the id is not empty.
List<ArtistName> onlineArtists(YtResult r) {
  if (r.artists.isEmpty) {
    return [
      for (final a in splitArtists(r.channel)) ArtistName(a.name, sep: a.sep),
    ];
  }
  return [
    for (var i = 0; i < r.artists.length; i++)
      ArtistName(
        r.artists[i],
        ytmId: r.artistIds.length > i && r.artistIds[i].isNotEmpty
            ? r.artistIds[i]
            : null,
        sep: i == r.artists.length - 1 ? '' : ', ',
      ),
  ];
}

/// The artists of [t]: the online ones when it is streamed and [online] is
/// known, otherwise its own `artist` text.
List<ArtistName> artistsOfTrack(Track t, YtResult? online) =>
    online != null && (isOnlineId(t.id) || t.kind == kStreamKind)
        ? onlineArtists(online)
        : libraryArtists(t);

sealed class ArtistLink {
  const ArtistLink();
}

class LibraryArtist extends ArtistLink {
  const LibraryArtist(this.artist);
  final ArtistSummary artist;
}

class OnlineArtist extends ArtistLink {
  const OnlineArtist(this.artist);
  final YtmArtistRef artist;
}

class ChooseArtists extends ArtistLink {
  const ChooseArtists(this.artists);
  final List<YtmArtistRef> artists;
}

class NoArtistLink extends ArtistLink {
  const NoArtistLink();
}

/// Library first, then the artist's YouTube Music page. The network is used
/// only when the library has nobody and there is no [ytmId]; its errors propagate.
class ArtistLinkResolver {
  const ArtistLinkResolver({required this.library, required this.search});

  final Future<ArtistSummary?> Function(String key) library;
  final Future<List<YtmArtistRef>> Function(String name) search;

  Future<ArtistLink> resolve(String name, {String? ytmId}) async {
    final local = await library(name.trim().toLowerCase());
    if (local != null) return LibraryArtist(local);
    if (ytmId != null && ytmId.isNotEmpty) {
      return OnlineArtist(YtmArtistRef(id: ytmId, name: name));
    }
    return switch (pickYtmArtist(name, await search(name))) {
      ExactArtist(:final artist) => OnlineArtist(artist),
      ChooseArtist(:final artists) => ChooseArtists(artists),
      NoArtist() => const NoArtistLink(),
    };
  }
}
