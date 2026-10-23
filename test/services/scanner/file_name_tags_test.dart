import 'package:codecore/services/scanner/file_name_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits artist and title and strips YouTube junk', () {
    final r = splitArtistTitle('Cesare Cremonini - Poetica (Official Video)');
    expect(r.artist, 'Cesare Cremonini');
    expect(r.title, 'Poetica');
    expect(splitArtistTitle('A - B [HD]').title, 'B');
    expect(splitArtistTitle('A - B (LYRICS)').title, 'B');
  });

  test('en and em dashes split too', () {
    expect(splitArtistTitle('A – B').artist, 'A');
    expect(splitArtistTitle('A — B').title, 'B');
  });

  test('no dash keeps the whole name as title', () {
    final r = splitArtistTitle('Poetica');
    expect(r.artist, '');
    expect(r.title, 'Poetica');
  });

  test('empty part means no split', () {
    final r = splitArtistTitle(' - Poetica');
    expect(r.artist, '');
    expect(r.title, '- Poetica');
  });
}
