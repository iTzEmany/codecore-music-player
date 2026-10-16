import 'dart:io';

import 'package:codecore/services/import/csv_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  group('detectCsvKind', () {
    test('by header', () {
      List<String> h(String s) => s.split(',');
      expect(detectCsvKind(h('track uri,track name,artist name(s)')), 'exportify');
      expect(detectCsvKind(h('track name,artist name,album,playlist name')),
          'tunemymusic');
      expect(detectCsvKind(h('title,artist,album,isrc,duration')), 'soundiiz');
      expect(detectCsvKind(h('uts,utc_time,artist,track')), 'lastfm');
      expect(detectCsvKind(h('song,band')), 'csv');
    });
  });

  group('TuneMyMusic (synthetic fixture)', () {
    final p = readCsvPlaylist('whatever.csv', fixture('synthetic_tunemymusic.csv'));

    test('rows, ISRC and album', () {
      expect(p.kind, 'tunemymusic');
      expect(p.rows.map((r) => r.title),
          ['Imagine', 'Wish You Were Here', "Blowin' in the Wind", 'Sigarette']);
      expect(p.rows.first.isrc, 'GBAYE1000769');
      expect(p.rows.first.album, 'Imagine');
      expect(p.rows.first.artists, ['John Lennon']);
      expect(p.rows.first.durationMs, isNull);
    });

    test('the playlist name inside the file wins over the file name', () {
      expect(p.name, 'Chill Evening');
    });
  });

  group('Soundiiz (synthetic fixture)', () {
    final p = readCsvPlaylist('Mix_2025.csv', fixture('synthetic_soundiiz.csv'));

    test('durations as m:ss and as seconds', () {
      expect(p.kind, 'soundiiz');
      expect(p.rows.map((r) => r.durationMs), [187000, 334000, 180000]);
    });

    test('indexes are consecutive', () {
      expect([for (final r in p.rows) r.index], [0, 1, 2]);
    });
  });

  group('Last.fm (synthetic fixture)', () {
    final p = readCsvPlaylist('scrobbles.csv', fixture('synthetic_lastfm.csv'));

    test('repeated songs are kept once, in order of first appearance', () {
      expect(p.kind, 'lastfm');
      expect(p.rows.map((r) => r.title), ['Sigarette', 'Imagine', 'Wish You Were Here']);
      expect([for (final r in p.rows) r.index], [0, 1, 2]);
    });

    test('the same song in another letter case is the same song', () {
      expect(p.rows.where((r) => r.title.toLowerCase() == 'imagine'), hasLength(1));
    });

    test('with no playlist column the file name names the playlist', () {
      expect(p.name, 'scrobbles');
    });
  });

  group('parseDurationMs', () {
    test('clock times', () {
      expect(parseDurationMs('3:07', headerSaysMs: false), 187000);
      expect(parseDurationMs('1:02:03', headerSaysMs: false), 3723000);
      expect(parseDurationMs('3:xx', headerSaysMs: false), isNull);
    });

    test('numbers: header says ms, or the size decides', () {
      expect(parseDurationMs('187000', headerSaysMs: true), 187000);
      expect(parseDurationMs('187000', headerSaysMs: false), 187000);
      expect(parseDurationMs('187', headerSaysMs: false), 187000);
      expect(parseDurationMs('187,5', headerSaysMs: false), 187500);
    });

    test('empty and junk', () {
      expect(parseDurationMs(null, headerSaysMs: false), isNull);
      expect(parseDurationMs('  ', headerSaysMs: false), isNull);
      expect(parseDurationMs('abc', headerSaysMs: false), isNull);
      expect(parseDurationMs('-5', headerSaysMs: false), isNull);
    });
  });

  group('generic CSV', () {
    test('any file with a title and an artist column', () {
      final p = readCsvPlaylist('mine.csv', 'Song,Band,Length\nA,B,200\n');
      expect(p.kind, 'csv');
      expect(p.rows.single.title, 'A');
      expect(p.rows.single.durationMs, 200000);
    });

    test('several artists separated by ;', () {
      final p = readCsvPlaylist('x.csv', 'Title,Artist\nA,"X; Y & Z"\n');
      expect(p.rows.single.artists, ['X', 'Y & Z']);
    });

    test('no title or no artist column is refused', () {
      expect(() => readCsvPlaylist('x.csv', 'a,b\n1,2\n'), throwsFormatException);
      expect(() => readCsvPlaylist('x.csv', 'Title,Year\nA,1999\n'),
          throwsFormatException);
    });

    test('rows without a title are counted as skipped', () {
      final p = readCsvPlaylist('x.csv', 'Title,Artist\n,B\nA,B\n');
      expect(p.rows, hasLength(1));
      expect(p.skipped, 1);
    });
  });
}
