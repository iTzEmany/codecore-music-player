import '../import/track_matcher.dart';

/// One person with one role on a track. The DB key is `nameKey + role`.
class TrackCredit {
  TrackCredit(this.name, this.role, this.source, {this.mbid})
      : nameKey = matchKey(name);

  final String name;
  final String nameKey;

  /// Lower-case role as the source spells it (`mixingengineer`, `guitar`).
  final String role;

  /// `deezer` or `musicbrainz`.
  final String source;

  /// MusicBrainz artist id, when the source has one.
  final String? mbid;
}

class DeezerContributors {
  const DeezerContributors(this.credits, {this.copyright, this.physicalReleaseDate});
  final List<TrackCredit> credits;
  final String? copyright;
  final String? physicalReleaseDate;
}

/// [data] is `results.DATA` of a gw `deezer.pageTrack` answer.
/// `main_artist` is dropped: the artist is already `tracks.artist`.
DeezerContributors parseDeezerContributors(Map<String, dynamic> data) {
  final credits = <TrackCredit>[];
  final contributors = data['SNG_CONTRIBUTORS'];
  if (contributors is Map) {
    contributors.forEach((role, names) {
      final r = role.toString().toLowerCase();
      if (r == 'main_artist' || names is! List) return;
      for (final n in names) {
        if (n is String && n.trim().isNotEmpty) {
          credits.add(TrackCredit(n.trim(), r, 'deezer'));
        }
      }
    });
  }
  String? text(Object? v) => v is String && v.isNotEmpty ? v : null;
  return DeezerContributors(_dedupe(credits),
      copyright: text(data['COPYRIGHT']),
      physicalReleaseDate: text(data['PHYSICAL_RELEASE_DATE']));
}

/// [recording] is a MusicBrainz `/recording/{mbid}?inc=artist-rels+work-rels+work-level-rels`
/// answer. Instrument relations take the instrument as role; work-to-work
/// and non-artist relations are ignored.
List<TrackCredit> parseMbCredits(Map<String, dynamic> recording) {
  final out = <TrackCredit>[];
  void fromRelations(Object? rels) {
    if (rels is! List) return;
    for (final rel in rels) {
      if (rel is! Map || rel['target-type'] != 'artist') continue;
      final artist = rel['artist'];
      if (artist is! Map || artist['name'] is! String) continue;
      final type = (rel['type'] as String? ?? '').toLowerCase();
      final attrs = [
        for (final a in rel['attributes'] as List? ?? const [])
          if (a is String) a.toLowerCase()
      ];
      final roles = type == 'instrument' && attrs.isNotEmpty ? attrs : [type];
      for (final role in roles) {
        if (role.isEmpty) continue;
        out.add(TrackCredit(artist['name'] as String, role, 'musicbrainz',
            mbid: artist['id'] as String?));
      }
    }
  }

  final rels = recording['relations'];
  fromRelations(rels);
  if (rels is List) {
    for (final rel in rels) {
      if (rel is Map && rel['target-type'] == 'work' && rel['work'] is Map) {
        fromRelations((rel['work'] as Map)['relations']);
      }
    }
  }
  return _dedupe(out);
}

/// Deezer first; MusicBrainz only adds the `nameKey + role` pairs still missing.
List<TrackCredit> mergeCredits(List<TrackCredit> deezer, List<TrackCredit> mb) =>
    _dedupe([...deezer, ...mb]);

List<TrackCredit> _dedupe(List<TrackCredit> all) {
  final seen = <String>{};
  return [
    for (final c in all)
      if (seen.add('${c.nameKey}\u0000${c.role}')) c
  ];
}
