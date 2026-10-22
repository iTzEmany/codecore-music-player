import '../online/ytm_artist.dart';

/// How many most-listened artists are followed automatically.
const kAutoFollowCount = 15;

/// What YouTube Music said about a most-listened artist name.
sealed class AutoResolution {
  const AutoResolution();
}

/// One single artist has that name.
class ResolvedArtist extends AutoResolution {
  const ResolvedArtist(this.artist);

  final YtmArtistRef artist;
}

/// Nobody has that name.
class NoMatch extends AutoResolution {
  const NoMatch();
}

/// Several could be it (or none with exactly that name): the user chooses.
class Ambiguous extends AutoResolution {
  const Ambiguous();
}

/// A most-listened artist that could not be linked by itself.
class ToConfirm {
  const ToConfirm(this.key, this.name, {required this.nobody});

  final String key, name;

  /// True when YouTube Music found nobody (not even a near name).
  final bool nobody;
}

class AutoFollowPlan {
  const AutoFollowPlan({
    this.toResolve = const [],
    this.toAdd = const [],
    this.toRemove = const [],
    this.toConfirm = const [],
  });

  /// Keys of the top artists nobody looked up yet.
  final List<String> toResolve;

  /// To follow automatically.
  final List<YtmArtistRef> toAdd;

  /// Ids of automatic artists that left the top.
  final List<String> toRemove;
  final List<ToConfirm> toConfirm;
}

/// Works out what to change so the automatic follows are the top artists.
///
/// - [top]: `(key, name)` of the most listened, best first.
/// - [followedIds]: everyone followed now (by hand or automatically);
///   [autoIds]: only the automatic ones; [excludedIds]: automatic artists the
///   user stopped following.
/// - [resolved]: lookups already made, by key.
///
/// Never touches artists followed by hand, never adds an excluded one, and
/// never guesses: a name with no single exact match goes to [AutoFollowPlan.toConfirm].
AutoFollowPlan planAutoFollow({
  required List<({String key, String name})> top,
  required Set<String> followedIds,
  required Set<String> autoIds,
  required Set<String> excludedIds,
  required Map<String, AutoResolution> resolved,
  int max = kAutoFollowCount,
}) {
  final wanted = top.take(max).toList();
  final toResolve = <String>[], toAdd = <YtmArtistRef>[], toConfirm = <ToConfirm>[];
  final keep = <String>{};
  for (final t in wanted) {
    final r = resolved[t.key];
    switch (r) {
      case null:
        toResolve.add(t.key);
      case ResolvedArtist(:final artist):
        keep.add(artist.id);
        if (!followedIds.contains(artist.id) && !excludedIds.contains(artist.id)) {
          toAdd.add(artist);
        }
      case NoMatch():
        toConfirm.add(ToConfirm(t.key, t.name, nobody: true));
      case Ambiguous():
        toConfirm.add(ToConfirm(t.key, t.name, nobody: false));
    }
  }
  // Artists whose lookup is still to do are not removed.
  final pending = toResolve.isNotEmpty;
  final toRemove = pending
      ? <String>[]
      : [for (final id in autoIds) if (!keep.contains(id)) id];
  return AutoFollowPlan(
    toResolve: toResolve,
    toAdd: toAdd,
    toRemove: toRemove,
    toConfirm: toConfirm,
  );
}
