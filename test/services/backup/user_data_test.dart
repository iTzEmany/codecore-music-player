import 'dart:convert';

import 'package:codecore/services/backup/user_data.dart';
import 'package:flutter_test/flutter_test.dart';

UserData sample() => const UserData(
      createdAt: 5,
      tracks: [
        TrackUserData(
          ref: TrackRef(
              folder: '/music',
              relPath: 'a/b.mp3',
              title: 'B',
              artist: 'A',
              durationMs: 1000,
              sha256: 'ff'),
          favorite: true,
          edit: TrackEditData(title: 'B2', artist: 'A2', year: 1999),
          lyricsPlain: 'la la',
          playCount: 3,
          lastPlayedAt: 9,
        ),
      ],
      playlists: [
        PlaylistData(name: 'Mix', createdAt: 1, items: [
          TrackRef(title: 'B', artist: 'A', durationMs: 1000),
          TrackRef(title: 'C'),
        ]),
      ],
      imports: [
        ImportData(
          playlistName: 'Mix',
          sourceName: 'mix.csv',
          createdAt: 2,
          status: 2,
          rows: [
            ImportRowData(
                rowIndex: 0, title: 'B', artists: 'A;Z', status: 2, isrc: 'X')
          ],
        ),
      ],
    );

void main() {
  test('JSON round trip keeps everything', () {
    final back = UserData.fromJson(
        jsonDecode(jsonEncode(sample().toJson())) as Map<String, dynamic>);
    expect(jsonEncode(back.toJson()), jsonEncode(sample().toJson()));
    final t = back.tracks.single;
    expect(t.favorite, isTrue);
    expect(t.edit!.year, 1999);
    expect(t.ref.relPath, 'a/b.mp3');
    expect(back.playlists.single.items.map((i) => i.title), ['B', 'C']);
    expect(back.imports.single.rows.single.artists, 'A;Z');
  });

  test('an unknown future format is refused', () {
    final j = sample().toJson()..['format'] = 2;
    expect(() => UserData.fromJson(j), throwsFormatException);
  });

  test('missing format is refused', () {
    expect(() => UserData.fromJson({'tracks': []}), throwsFormatException);
  });

  test('unknown extra fields are ignored', () {
    final j = jsonDecode(jsonEncode(sample().toJson())) as Map<String, dynamic>
      ..['future'] = {'x': 1};
    (j['tracks'] as List).first['whatever'] = 7;
    expect(UserData.fromJson(j).tracks, hasLength(1));
  });

  test('optional fields are omitted from the JSON', () {
    const t = TrackUserData(ref: TrackRef(title: 'x'));
    expect(t.toJson().keys, ['ref']);
  });
}
