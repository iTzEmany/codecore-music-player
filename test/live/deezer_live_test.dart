// Opt-in: 20 well-known songs searched on the real Deezer API the way the
// enrichment does (ISRC first, then text search), plus a box set that must not
// be written as the album. A failure here means Deezer changed its answers.
//   CODECORE_LIVE=1 flutter test test/live/deezer_live_test.dart
import 'dart:io';

import 'package:codecore/services/online/deezer_client.dart';
import 'package:codecore/services/online/deezer_match.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:flutter_test/flutter_test.dart';

const _songs = [
  ('Bohemian Rhapsody', 'Queen', 'A Night At The Opera', 354000),
  ('Blinding Lights', 'The Weeknd', 'After Hours', 200000),
  ('Smells Like Teen Spirit', 'Nirvana', 'Nevermind', 301000),
  ('Billie Jean', 'Michael Jackson', 'Thriller', 294000),
  ('Wonderwall', 'Oasis', "(What's The Story) Morning Glory?", 258000),
  ('Rolling in the Deep', 'Adele', '21', 228000),
  ('Hotel California', 'Eagles', 'Hotel California', 391000),
  (
    'Bad Guy',
    'Billie Eilish',
    'WHEN WE ALL FALL ASLEEP, WHERE DO WE GO?',
    194000,
  ),
  ('Shape of You', 'Ed Sheeran', '÷', 233000),
  ('Seven Nation Army', 'The White Stripes', 'Elephant', 232000),
  ('Get Lucky', 'Daft Punk', 'Random Access Memories', 369000),
  ('Volare', 'Domenico Modugno', null, 214000),
  ('La canzone del sole', 'Lucio Battisti', null, 330000),
  ('Zitti e buoni', 'Måneskin', 'Teatro d\'ira - Vol. I', 194000),
  ('Bella ciao', 'Goran Bregović', null, null),
  (
    'Viva la Vida',
    'Coldplay',
    'Viva La Vida or Death and All His Friends',
    242000,
  ),
  ('Uptown Funk', 'Mark Ronson', 'Uptown Special', 270000),
  ('Clair de lune', 'Claude Debussy', null, null),
  ('Levitating', 'Dua Lipa', 'Future Nostalgia', 203000),
  ('Comfortably Numb', 'Pink Floyd', 'The Wall', 382000),
];

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1';
  final skip = live ? false : 'set CODECORE_LIVE=1';
  final deezer = DeezerClient(DioWebClient());

  test(
    'most of 20 real songs are found, with album and year',
    () async {
      var found = 0, withAlbum = 0;
      for (final (title, artist, album, ms) in _songs) {
        final want = DeezerWant(
          title: title,
          artist: artist,
          album: album,
          durationMs: ms,
        );
        final hit = pickDeezerTrack(
          want,
          await deezer.searchTracks(deezerQuery(want)),
        );
        final a = hit?.album == null
            ? null
            : await deezer.album(hit!.album!.id);
        final usable = a != null && checkEdition(album, a).albumUsable;
        if (hit != null) found++;
        if (usable) withAlbum++;
        // ignore: avoid_print
        print(
          '${hit == null ? '--' : 'ok'} $artist – $title → '
          '${hit?.isrc ?? '-'} | ${a?.title ?? '-'} (${a?.recordType ?? '-'}, '
          '${a?.releaseDate ?? '-'}) ${usable ? 'album OK' : 'album no'}',
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      expect(found, greaterThanOrEqualTo(16));
      expect(withAlbum, greaterThanOrEqualTo(12));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  // Deezer answers an ISRC with any release of that recording: here a
  // compilation, which must give the ISRC but not its album.
  test('an ISRC hit on a compilation keeps the local album', () async {
    const want = DeezerWant(
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      album: 'A Night At The Opera',
    );
    final hit = await deezer.trackByIsrc('GBUM71029604');
    expect(hit, isNotNull);
    expect(acceptIsrcHit(want, hit!), isTrue);
    final a = await deezer.album(hit.album!.id);
    // ignore: avoid_print
    print(
      'ISRC → ${hit.title} | ${a?.title} (${a?.recordType}, ${a?.nbTracks} brani)',
    );
    expect(a, isNotNull);
    if (a!.recordType == 'compile' || a.nbTracks > 40) {
      expect(checkEdition(want.album, a).albumUsable, isFalse);
    }
  }, skip: skip);
}
