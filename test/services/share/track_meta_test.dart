import 'package:codecore/services/share/track_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const full = TrackMeta(
    title: 'T',
    artist: 'A',
    albumArtist: 'AA',
    album: 'Al',
    year: 2001,
    genre: 'Rock',
    trackNumber: 3,
    discNumber: 1,
    isrc: 'USRC17607839',
    lyricsPlain: 'la la',
    lyricsSynced: '[00:01.00]la la',
    enrichStatus: 1,
    youtubeId: 'dQw4w9WgXcQ',
  );

  test('round trip keeps every field', () {
    final back = TrackMeta.tryParse(full.toJson())!;
    expect(back.toJson(), full.toJson());
    expect(back.toJson().length, 13);
  });

  test('a bad field becomes null and the others stay', () {
    final json = full.toJson()
      ..['year'] = 99999
      ..['isrc'] =
          'USRC1760783' // 11 chars
      ..['trackNumber'] = -1
      ..['title'] = 'x' * 5000
      ..['enrichStatus'] = 7
      ..['lyricsSynced'] = 'no timestamps'
      ..['youtubeId'] = 'short';
    final m = TrackMeta.tryParse(json)!;
    expect(m.year, isNull);
    expect(m.isrc, isNull);
    expect(m.trackNumber, isNull);
    expect(m.enrichStatus, isNull);
    expect(m.lyricsSynced, isNull);
    expect(m.youtubeId, isNull);
    expect(m.title!.length, 200);
    expect(m.artist, 'A');
    expect(m.discNumber, 1);
    expect(m.lyricsPlain, 'la la');
  });

  test('a huge LRC offset does not throw', () {
    final m = TrackMeta.tryParse({
      'lyricsSynced': '[offset:99999999999999999999]\n[00:01.00]a',
    });
    expect(m!.lyricsSynced, isNotNull);
  });

  test('isrc is upper-cased', () {
    expect(TrackMeta.tryParse({'isrc': 'usrc17607839'})!.isrc, 'USRC17607839');
  });

  test('non-map gives null, empty map gives all-null fields', () {
    expect(TrackMeta.tryParse('x'), isNull);
    expect(TrackMeta.tryParse(null), isNull);
    expect(TrackMeta.tryParse(<String, Object?>{})!.toJson(), isEmpty);
  });
}
