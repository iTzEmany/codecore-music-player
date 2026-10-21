import '../../data/db/app_database.dart' show Track;
import '../../data/repositories/library_queries.dart' show ArtistSummary;
import '../import/track_matcher.dart' show matchKey, matchTitleKey;
import 'query_cleaner.dart' show extractPrimaryArtist;
import 'youtube_service.dart' show YtResult;

/// How far two lengths may differ for the same recording.
const _lengthSlack = Duration(seconds: 5);

String _artistKey(String name) => matchKey(extractPrimaryArtist(name));

/// The library artist that is [name] on YouTube Music: same main artist once
/// case, accents and «feat.» are ignored («PINK FLOYD» = «Pink Floyd»). With
/// several (spelled differently in the tags) the one with most tracks.
ArtistSummary? localArtistFor(String name, List<ArtistSummary> artists) {
  final want = _artistKey(name);
  if (want.isEmpty) return null;
  ArtistSummary? best;
  for (final a in artists) {
    final n = a.name;
    if (n == null || _artistKey(n) != want) continue;
    if (best == null || a.trackCount > best.trackCount) best = a;
  }
  return best;
}

/// The songs of one artist's library, to tell which online songs are already
/// there even when they came from a file or from another video.
class LibraryOverlap {
  LibraryOverlap(Iterable<Track> artistTracks) {
    for (final t in artistTracks) {
      (_byTitle[matchTitleKey(t.title)] ??= []).add(t.durationMs);
    }
  }

  final _byTitle = <String, List<int>>{};

  /// Same title (remaster and feat. tags ignored) and, when both lengths are
  /// known, a length within 5 s (a song with no length matches on the title).
  bool owns(YtResult r) {
    final lengths = _byTitle[matchTitleKey(r.title)];
    if (lengths == null) return false;
    final want = r.duration;
    if (want == null) return true;
    return lengths.any((ms) =>
        ms <= 0 || (Duration(milliseconds: ms) - want).abs() <= _lengthSlack);
  }
}

/// Whether [r] is one of [artistTracks] (see [LibraryOverlap.owns]).
bool ownedIn(List<Track> artistTracks, YtResult r) => LibraryOverlap(artistTracks).owns(r);
