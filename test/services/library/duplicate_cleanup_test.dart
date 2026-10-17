import 'dart:io';

import 'package:codecore/services/library/duplicate_cleanup.dart';
import 'package:codecore/services/library/duplicate_finder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

DupEntry _e(int id, String path, {int size = 4}) => DupEntry(
  id: id,
  path: path,
  title: 'S',
  artist: 'A',
  durationMs: 1000,
  format: 'mp3',
  sizeBytes: size,
);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('clean'));
  tearDown(() => dir.deleteSync(recursive: true));

  String file(String name) {
    final f = File(p.join(dir.path, name))..writeAsBytesSync([1, 2, 3, 4]);
    return f.path;
  }

  test('deletes the duplicates and never the kept file', () async {
    final keep = _e(1, file('keep.flac'));
    final a = _e(2, file('a.mp3'));
    final b = _e(3, file('b.mp3'));

    final r = await deleteDuplicateFiles(keep, [a, b]);

    expect(r.deleted.map((e) => e.id), [2, 3]);
    expect(r.freedBytes, 8);
    expect(File(keep.path).existsSync(), isTrue);
    expect(File(a.path).existsSync(), isFalse);
    expect(File(b.path).existsSync(), isFalse);
  });

  test('a file that is already gone counts as deleted', () async {
    final keep = _e(1, file('keep.flac'));
    final gone = _e(2, p.join(dir.path, 'gone.mp3'));
    final r = await deleteDuplicateFiles(keep, [gone]);
    expect(r.deleted, [gone]);
    expect(r.failed, isEmpty);
  });

  test('one failure is collected with its reason and the others still go', () async {
    final keep = _e(1, file('keep.flac'));
    final bad = _e(2, file('bad.mp3'));
    final ok = _e(3, file('ok.mp3'));

    final r = await deleteDuplicateFiles(
      keep,
      [bad, ok],
      deleter: (path) async {
        if (path == bad.path) {
          throw FileSystemException('x', path, const OSError('Permission denied', 13));
        }
        File(path).deleteSync();
      },
    );

    expect(r.deleted, [ok]);
    expect(r.failed.keys, [bad]);
    expect(r.failed[bad], 'Permission denied');
    expect(File(bad.path).existsSync(), isTrue);
  });

  test('the kept track listed among the drops is left alone', () async {
    final keep = _e(1, file('keep.flac'));
    final r = await deleteDuplicateFiles(keep, [keep]);
    expect(r.skipped, [keep]);
    expect(File(keep.path).existsSync(), isTrue);
  });

  test('a duplicate that is a link to the kept file is not deleted', () async {
    final keep = _e(1, file('keep.flac'));
    final link = p.join(dir.path, 'link.flac');
    Link(link).createSync(keep.path);

    final r = await deleteDuplicateFiles(keep, [_e(2, link)]);

    expect(r.skipped.map((e) => e.id), [2]);
    expect(r.deleted, isEmpty);
    expect(File(keep.path).existsSync(), isTrue);
    expect(Link(link).existsSync(), isTrue);
  }, skip: Platform.isWindows ? 'symlinks need privileges on Windows' : false);
}
