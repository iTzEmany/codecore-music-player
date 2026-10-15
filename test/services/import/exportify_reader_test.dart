import 'dart:io';

import 'package:codecore/services/import/exportify_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real Exportify file: name, count and first rows', () {
    final text = File('test/fixtures/Just_a_mood.csv').readAsStringSync();
    final p = readExportify('Just_a_mood.csv', text);
    expect(p.name, 'Just a mood');
    expect(p.rows, hasLength(34));
    expect(p.skipped, 0);
    final r = p.rows.first;
    expect(r.index, 0);
    expect(r.title, 'Singalong Junk - Remastered 2011');
    expect(r.artists, ['Paul McCartney']);
    expect(r.album, 'McCartney (Archive Collection)');
    expect(r.durationMs, 156280);
    expect(r.isrc, 'GBCCS1000114');
    expect(r.spotifyUri, 'spotify:track:4Fr1MF0N2VAh9niAYGf9wE');
    expect(p.rows[3].title, 'Sigarette');
    expect(p.rows[3].artists, ['Lucio Corsi']);
  });

  test('several artists are separated by semicolons', () {
    final text = File('test/fixtures/Just_a_mood.csv').readAsStringSync();
    final p = readExportify('x.csv', text);
    final banana = p.rows.firstWhere((r) => r.title == 'Banana Republic');
    expect(banana.artists, ['Lucio Dalla', 'Francesco De Gregori']);
    expect(banana.primaryArtist, 'Lucio Dalla');
  });

  test('columns are found by header, in any order', () {
    const csv = 'Duration (ms),Artist Name(s),Track Name,Track URI\n'
        '1000,Someone,Song,spotify:track:abc\n';
    final p = readExportify('a/b/My_List.CSV', csv);
    expect(p.name, 'My List');
    expect(p.rows.single.title, 'Song');
    expect(p.rows.single.durationMs, 1000);
  });

  test('podcast episodes, local files and untitled rows are skipped', () {
    const csv = 'Track URI,Track Name,Artist Name(s),Duration (ms)\n'
        'spotify:track:1,A,X,1\n'
        'spotify:episode:2,Pod,Y,1\n'
        'spotify:local:3,Mine,Z,1\n'
        'spotify:track:4,,X,1\n';
    final p = readExportify('l.csv', csv);
    expect(p.rows.map((r) => r.title), ['A']);
    expect(p.skipped, 3);
  });

  test('a file that is not from Exportify is rejected', () {
    expect(() => readExportify('x.csv', 'a,b\n1,2\n'),
        throwsA(isA<FormatException>()));
    expect(() => readExportify('x.csv', ''), throwsA(isA<FormatException>()));
  });

  test('isolate variant gives the same result', () async {
    final text = File('test/fixtures/Just_a_mood.csv').readAsStringSync();
    final p = await readExportifyInIsolate('Just_a_mood.csv', text);
    expect(p.rows, hasLength(34));
  });
}
