import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:codecore/services/import/csv_profiles.dart';
import 'package:codecore/services/import/exportify_zip.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _zip(Map<String, String> files) {
  final a = Archive();
  files.forEach((n, c) => a.add(ArchiveFile.string(n, c)));
  return Uint8List.fromList(ZipEncoder().encode(a));
}

String _csv(String title) =>
    'Track URI,Track Name,Artist Name(s)\nspotify:track:$title,$title,Art\n';

void main() {
  test('a ZIP with 3 entries gives 3 playlists', () async {
    final r = await readExportifyZip(
      _zip({'a.csv': _csv('a'), 'b.csv': _csv('b'), 'c.csv': _csv('c')}),
    );
    expect(r.entries.map((e) => e.fileName), ['a.csv', 'b.csv', 'c.csv']);
    expect(r.skipped, 0);
  });

  test(
    'non-CSV and nested entries are ignored, unreadable CSV counted',
    () async {
      final r = await readExportifyZip(
        _zip({
          'a.csv': _csv('a'),
          'readme.txt': 'hi',
          'dir/b.csv': _csv('b'),
          'albums.csv': 'Album,Year\nx,1999\n',
        }),
      );
      expect(r.entries.length, 1);
      expect(r.skipped, 1);
    },
  );

  test('an entry over the size limit is skipped', () async {
    final big = _csv('a') + 'x' * (kMaxCsvBytes + 1);
    final r = await readExportifyZip(
      _zip({'big.csv': big, 'a.csv': _csv('a')}),
    );
    expect(r.entries.length, 1);
    expect(r.skipped, 1);
  });

  test('a ZIP over 20 MB throws', () {
    expect(
      readExportifyZip(Uint8List(kMaxZipBytes + 1)),
      throwsA(isA<FormatException>()),
    );
  });

  test('"Just a mood" matches just_a_mood.csv', () async {
    final csv = File('test/fixtures/Just_a_mood.csv').readAsStringSync();
    final r = await readExportifyZip(_zip({'just_a_mood.csv': csv}));
    expect(r.entries.single.playlist.rows, isNotEmpty);
    final m = matchExportifyEntries(
      [r.entries.single.fileName],
      [
        (id: 7, name: 'Just a mood', lastImportName: null),
        (id: 8, name: 'Other', lastImportName: null),
      ],
    );
    expect(m.single, (playlistId: 7, ambiguous: false));
  });

  test('exportifyKey follows Exportify', () {
    expect(exportifyKey('Rock: the "best", vol. 2'), 'rock_the_best_vol_2');
  });

  test('last import name matches; unknown name is a new playlist', () {
    final m = matchExportifyEntries(
      ['x.csv', 'z.csv'],
      [(id: 1, name: 'Renamed', lastImportName: 'X.csv')],
    );
    expect(m[0], (playlistId: 1, ambiguous: false));
    expect(m[1], (playlistId: null, ambiguous: false));
  });

  test('two playlists with the same key are ambiguous', () {
    final m = matchExportifyEntries(
      ['rock.csv'],
      [
        (id: 1, name: 'Rock', lastImportName: null),
        (id: 2, name: 'rock', lastImportName: null),
      ],
    );
    expect(m.single.ambiguous, isTrue);
  });

  test('a (1) suffix is ambiguous', () {
    final m = matchExportifyEntries(
      ['rock (1).csv'],
      [(id: 1, name: 'Rock', lastImportName: null)],
    );
    expect(m.single.ambiguous, isTrue);
  });
}
