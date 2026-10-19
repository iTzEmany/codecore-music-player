import 'package:codecore/core/import_row.dart';
import 'package:codecore/services/backup/track_resolver.dart';
import 'package:codecore/services/backup/user_data.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryEntryLite lib(int id, String title, String? artist, int ms) =>
    LibraryEntryLite(id: id, title: title, artist: artist, durationMs: ms);

void main() {
  final entries = [
    lib(1, 'One', 'Band', 180000),
    lib(2, 'Two', 'Band', 200000),
    lib(3, 'Same', 'Band', 100000),
    lib(4, 'Same', 'Band', 160000),
    lib(5, 'Twin', 'Band', 100000),
    lib(6, 'Twin', 'Band', 100000),
  ];

  test('same relative path under a different root folder', () {
    final r = TrackResolver(entries, {1: 'album/one.mp3', 2: 'album/two.mp3'});
    expect(
        r.resolve(const TrackRef(
            folder: '/old/root', relPath: 'album/two.mp3', title: 'whatever')),
        2);
  });

  test('a Windows path matches a Linux one, ignoring case when asked', () {
    final loose = TrackResolver(entries, {1: 'Album/One.mp3'},
        caseInsensitive: true);
    const ref = TrackRef(relPath: r'album\one.mp3', title: 'zzz');
    expect(loose.resolve(ref), 1);
    final strict = TrackResolver(entries, {1: 'Album/One.mp3'});
    expect(strict.resolve(const TrackRef(relPath: r'Album\One.mp3', title: 'zzz')), 1);
    expect(strict.resolve(ref), isNull);
  });

  test('a received file without tags matches by file name', () {
    final r = TrackResolver([
      lib(1, 'Band - One', null, 180500),
      lib(2, 'Band - Two', null, 200000),
    ], {1: 'Ricevuti/Band - One.mp3', 2: 'Ricevuti/Band - Two.mp3'});
    const ref = TrackRef(
        relPath: 'Band - One.mp3', title: 'One', artist: 'Band', durationMs: 180000);
    expect(r.resolve(ref), 1);
    expect(
        r.resolve(const TrackRef(
            relPath: 'Band - One.mp3', title: 'One', durationMs: 90000)),
        isNull);
  });

  test('title and artist when the path does not match', () {
    final r = TrackResolver(entries, {});
    expect(
        r.resolve(const TrackRef(
            relPath: 'gone.mp3', title: 'ONE', artist: 'band', durationMs: 181000)),
        1);
  });

  test('two namesakes with different lengths: the closest wins', () {
    final r = TrackResolver(entries, {});
    expect(
        r.resolve(const TrackRef(title: 'Same', artist: 'Band', durationMs: 159000)),
        4);
    expect(
        r.resolve(const TrackRef(title: 'Same', artist: 'Band', durationMs: 101500)),
        3);
  });

  test('too far in length is not a match', () {
    final r = TrackResolver(entries, {});
    expect(
        r.resolve(const TrackRef(title: 'One', artist: 'Band', durationMs: 190000)),
        isNull);
  });

  test('a tie resolves to nothing', () {
    final r = TrackResolver(entries, {});
    expect(
        r.resolve(const TrackRef(title: 'Twin', artist: 'Band', durationMs: 100000)),
        isNull);
  });

  test('sha256 is the last resort', () {
    final r = TrackResolver(entries, {}, sha256ById: {2: 'abc'});
    expect(r.resolve(const TrackRef(title: 'Renamed', sha256: 'abc')), 2);
    expect(r.resolve(const TrackRef(title: 'Renamed', sha256: 'zzz')), isNull);
  });
}
