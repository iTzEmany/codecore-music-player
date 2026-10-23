import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/deezer_match.dart';
import 'package:codecore/services/online/deezer_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<dynamic, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/deezer/$name.json').readAsStringSync())
        as Map;

List<DeezerTrack> _search(String name) => [
  for (final j in _json(name)['data'] as List) DeezerTrack.fromJson(j as Map),
];

void main() {
  const viva = DeezerWant(
    title: 'Viva la Vida',
    artist: 'Coldplay',
    album: 'Viva La Vida or Death and All His Friends',
    durationMs: 242000,
  );

  test('query has the album only when known', () {
    expect(deezerQuery(viva), contains('or Death'));
    expect(
      deezerQuery(const DeezerWant(title: 'Poetica', artist: 'Cremonini')),
      'Cremonini Poetica',
    );
  });

  test('Viva la Vida: the studio track, never the instrumental', () {
    final pick = pickDeezerTrack(viva, _search('search_viva_la_vida_album'));
    expect(pick?.duration, 242);
    expect(pick?.title, 'Viva La Vida');
    expect(pickDeezerTrack(viva, _search('search_viva_la_vida')), isNull);
  });

  test('a length 4 s off is refused', () {
    final far = DeezerWant(
      title: viva.title,
      artist: viva.artist,
      album: viva.album,
      durationMs: 246000,
    );
    expect(pickDeezerTrack(far, _search('search_viva_la_vida_album')), isNull);
  });

  test('text search without a local length gives nothing', () {
    final noLength = DeezerWant(
      title: viva.title,
      artist: viva.artist,
      album: viva.album,
    );
    expect(
      pickDeezerTrack(noLength, _search('search_viva_la_vida_album')),
      isNull,
    );
  });

  test('ISRC hit: accepted within 3 s, refused beyond', () {
    final t = DeezerTrack.fromJson(_json('track_isrc_corsi'));
    expect(
      acceptIsrcHit(const DeezerWant(title: 'S', durationMs: 182000), t),
      isTrue,
    );
    expect(
      acceptIsrcHit(const DeezerWant(title: 'S', durationMs: 183500), t),
      isFalse,
    );
    expect(acceptIsrcHit(const DeezerWant(title: 'S'), t), isTrue);
  });

  test('Imagine: track yes, album «Signature Box» no (119 tracks)', () {
    final box = DeezerAlbum.fromJson(_json('album_signature_box'));
    expect(checkEdition(null, box).albumUsable, isFalse);
    expect(checkEdition('Imagine', box).albumUsable, isFalse);
  });

  test('Lucio Corsi: album usable, empty or equal local album', () {
    final a = DeezerAlbum.fromJson(_json('album_volevo_essere_un_duro'));
    expect(checkEdition('Volevo essere un duro', a).albumUsable, isTrue);
    expect(checkEdition('', a).albumUsable, isTrue);
  });

  test('a different local album leaves only the ISRC', () {
    final a = DeezerAlbum.fromJson(_json('album_volevo_essere_un_duro'));
    expect(checkEdition('Greatest Hits', a).albumUsable, isFalse);
  });
}
