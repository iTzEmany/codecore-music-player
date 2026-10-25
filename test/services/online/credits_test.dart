import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:codecore/services/online/credits.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File('test/fixtures/$path.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> _gw(String n) =>
    _json('deezer/$n')['results']['DATA'] as Map<String, dynamic>;

Set<String> _pairs(List<TrackCredit> c) =>
    {for (final x in c) '${x.name}|${x.role}'};

void main() {
  test('Lose Yourself: roles, names, copyright and physical date', () {
    final r = parseDeezerContributors(_gw('gw_page_track_lose_yourself'));
    final byRole = <String, Set<String>>{};
    for (final c in r.credits) {
      (byRole[c.role] ??= {}).add(c.name);
    }
    expect(byRole.keys.toSet(), {
      'mixingengineer', 'drumprogrammer', 'additionalproducer', 'composer',
      'author', 'recordingengineer', //
    });
    expect(byRole['composer'], {'Jeff Bass', 'Luis Resto', 'Marshall Mathers'});
    expect(r.credits.every((c) => c.source == 'deezer'), isTrue);
    expect(r.copyright, '© 2005 Aftermath Entertainment/Interscope Records');
    expect(r.physicalReleaseDate, '2005-12-06');
  });

  test('One More Time: role with spaces kept, no composer', () {
    final r = parseDeezerContributors(_gw('gw_page_track_one_more_time'));
    final roles = r.credits.map((c) => c.role).toSet();
    expect(roles, {'drum machine drums', 'masteringengineer', 'author'});
    expect(r.credits.where((c) => c.role == 'drum machine drums').length, 2);
  });

  test('Get Lucky: 6 instruments, 2 vocals, 2 producers, 4 writers, no work-to-work', () {
    final c = parseMbCredits(_json('musicbrainz/recording_credits_get_lucky'));
    int n(bool Function(String) f) => c.where((x) => f(x.role)).length;
    expect(n((r) => r == 'vocal'), 2);
    expect(n((r) => r == 'producer'), 2);
    expect(n((r) => r == 'writer'), 4);
    expect(n((r) => !{'vocal', 'producer', 'writer'}.contains(r)), 6);
    expect(c.length, 14);
    expect(_pairs(c), contains('Nile Rodgers|guitar'));
    expect(_pairs(c), contains('Paul Jackson, Jr.|guitar'));
    expect(c.firstWhere((x) => x.name == 'Nathan East').mbid,
        'aa82f6eb-ded9-4c0b-951d-2e638ca25c76');
  });

  test('merge: Deezer first, MusicBrainz only adds missing nameKey+role', () {
    final merged = mergeCredits(
      [TrackCredit('A', 'composer', 'deezer'), TrackCredit('A', 'composer', 'deezer')],
      [TrackCredit('Á', 'composer', 'musicbrainz'), TrackCredit('B', 'guitar', 'musicbrainz')],
    );
    expect(merged.map((c) => '${c.name}|${c.role}|${c.source}'),
        ['A|composer|deezer', 'B|guitar|musicbrainz']);
  });
}
