import 'package:codecore/services/online/query_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const table = [
    ['01 - Car Radio (Official Video)', 'twenty one pilots', 'Car Radio', 'twenty one pilots'],
    ['Queen – Bohemian Rhapsody (Official Video Remastered)', '', 'Bohemian Rhapsody', 'Queen'],
    ['Jay-Z - Empire State of Mind', '', 'Empire State of Mind', 'Jay-Z'],
    ['Don’t Stop Believin’', 'Journey', "Don't Stop Believin'", 'Journey'],
    ['song.mp3', 'Artist - Topic', 'song', 'Artist'],
    // extra cases
    ['Spider-Man Theme', 'Unknown', 'Spider-Man Theme', 'Unknown'],
    ['Adele - Hello [Official Audio]', 'Adele VEVO', 'Hello', 'Adele'],
    ['Imagine Dragons - Believer (Lyric Video)', 'Sconosciuto', 'Believer', 'Imagine Dragons'],
    ['12. Hotel California', 'Eagles', 'Hotel California', 'Eagles'],
    ['Song - Live', 'Band', 'Song - Live', 'Band'],
  ];

  for (final r in table) {
    test('${r[0]} / ${r[1]}', () {
      final c = cleanSearchQuery(r[0], r[1]);
      expect(c.title, r[2]);
      expect(c.artist, r[3]);
    });
  }

  test('extractPrimaryArtist', () {
    expect(extractPrimaryArtist('A & B'), 'A');
    expect(extractPrimaryArtist('A feat. B'), 'A');
    expect(extractPrimaryArtist('A ft B'), 'A');
    expect(extractPrimaryArtist('Solo'), 'Solo');
    expect(extractPrimaryArtist(', X'), ', X');
  });

  test('coreTitle', () {
    expect(coreTitle('Car Radio (Live)'), 'Car Radio');
    expect(coreTitle('Song (feat. X)'), 'Song (feat. X)');
    expect(coreTitle('Heathens (MTV Unplugged) [Live]'), 'Heathens');
  });
}
