import '../import/track_matcher.dart' show matchKey;
import 'query_cleaner.dart' show extractPrimaryArtist;
import 'ytm_artist.dart';

/// How many artists the choice sheet offers.
const _choices = 3;

/// What to do with the artists YouTube Music found for a library artist.
sealed class YtmArtistPick {
  const YtmArtistPick();
}

/// One single artist has that name: open it.
class ExactArtist extends YtmArtistPick {
  const ExactArtist(this.artist);

  final YtmArtistRef artist;
}

/// None is certain: let the user choose among the first few.
class ChooseArtist extends YtmArtistPick {
  const ChooseArtist(this.artists);

  final List<YtmArtistRef> artists;
}

/// YouTube Music found nobody.
class NoArtist extends YtmArtistPick {
  const NoArtist();
}

/// Opens an artist by itself only when exactly one of [found] has the name of
/// [localName] (case, accents and «feat.» ignored); otherwise the first three
/// are offered, and nothing when [found] is empty.
YtmArtistPick pickYtmArtist(String localName, List<YtmArtistRef> found) {
  if (found.isEmpty) return const NoArtist();
  final full = matchKey(localName);
  final main = matchKey(extractPrimaryArtist(localName));
  final same = [
    for (final a in found)
      if (full.isNotEmpty && (matchKey(a.name) == full || matchKey(a.name) == main)) a,
  ];
  if (same.length == 1) return ExactArtist(same.single);
  return ChooseArtist(found.take(_choices).toList());
}
