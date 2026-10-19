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

  group('Exportify', () {
    test('real file: name, kind, count and first rows', () {
      final p = readCsvPlaylist('Just_a_mood.csv', fixture('Just_a_mood.csv'));
      expect(p.name, 'Just a mood');
      expect(p.kind, 'exportify');
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

    test('columns are found by header, in any order', () {
      const csv = 'Duration (ms),Artist Name(s),Track Name,Track URI\n'
          '1000,Someone,Song,spotify:track:abc\n';
      final p = readCsvPlaylist('a/b/My_List.CSV', csv);
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
      final p = readCsvPlaylist('l.csv', csv);
      expect(p.rows.map((r) => r.title), ['A']);
      expect(p.skipped, 3);
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
  });

  group('Last.fm (synthetic fixture)', () {
    final p = readCsvPlaylist('scrobbles.csv', fixture('synthetic_lastfm.csv'));

    test('repeated songs are kept once (in any letter case), in order of first '
        'appearance, with consecutive indexes', () {
      expect(p.kind, 'lastfm');
      // The fixture has «Sigarette» twice and «Imagine» / «imagine».
      expect(p.rows.map((r) => r.title), ['Sigarette', 'Imagine', 'Wish You Were Here']);
      expect([for (final r in p.rows) r.index], [0, 1, 2]);
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
      expect(p.rows.single.primaryArtist, 'X');
    });

    test('an empty file, or no title or no artist column, is refused', () {
      expect(() => readCsvPlaylist('x.csv', ''), throwsFormatException);
      expect(() => readCsvPlaylist('x.csv', 'a,b\n1,2\n'), throwsFormatException);
      expect(() => readCsvPlaylist('x.csv', 'Title,Year\nA,1999\n'),
          throwsFormatException);
    });
  });

  group('size limits', () {
    String rows(int n) {
      final b = StringBuffer('Track Name,Artist Name(s)\n');
      for (var i = 0; i < n; i++) {
        b.writeln('t$i,a');
      }
      return b.toString();
    }

    test('exactly the maximum number of rows is accepted, one more is not', () {
      expect(readCsvPlaylist('ok.csv', rows(kMaxCsvRows)).rows, hasLength(kMaxCsvRows));
      expect(() => readCsvPlaylist('big.csv', rows(kMaxCsvRows + 1)),
          throwsA(isA<CsvTooLargeException>()));
    });

    test('file size is checked before reading', () {
      expect(() => checkCsvSize(kMaxCsvBytes + 1),
          throwsA(isA<CsvTooLargeException>()));
      checkCsvSize(kMaxCsvBytes);
    });
  });
}
