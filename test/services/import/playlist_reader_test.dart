import 'dart:typed_data';
import 'dart:convert';

import 'package:codecore/services/import/playlist_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the extension is case-insensitive and ignores folders', () {
    const csv = 'Track Name,Artist Name(s)\nA,B\n';
    expect(readPlaylistFile('/x/y/LIST.CSV', csv).rows, hasLength(1));
    expect(readPlaylistFile(r'C:\x\list.csv', csv).rows, hasLength(1));
  });

  test('an unknown extension lists what is supported', () {
    expect(
        () => readPlaylistFile('list.txt', 'x'),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', allOf(contains('txt'), contains('csv')))));
    expect(() => readPlaylistFile('noextension', 'x'), throwsFormatException);
  });

  test('decoding: UTF-8, then Latin-1 for old .m3u, lenient for the rest', () {
    final utf = utf8.encode('Felicità');
    expect(decodePlaylistBytes('a.m3u8', utf8Bytes(utf)), 'Felicità');
    final latin = latin1.encode('Felicità');
    expect(decodePlaylistBytes('a.m3u', utf8Bytes(latin)), 'Felicità');
    expect(decodePlaylistBytes('a.csv', utf8Bytes(latin)), contains('\uFFFD'),
        reason: 'not valid UTF-8 and not an .m3u: replacement character');
  });

  test('the isolate variant gives the same result', () async {
    final p = await readPlaylistFileInIsolate(
        'x.csv', 'Track Name,Artist Name(s)\nA,B\n');
    expect(p.rows.single.title, 'A');
  });
}

Uint8List utf8Bytes(List<int> b) => Uint8List.fromList(b);
