import 'dart:io';

import 'package:codecore/services/covers/cover_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late CoverStore store;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cov');
    store = CoverStore(Directory(p.join(tmp.path, 'c')));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('saves once per album', () async {
    final k1 = await store.saveFromBytes('a|b', [1, 2], 'image/jpeg');
    final k2 = await store.saveFromBytes('a|b', [9, 9, 9], 'image/jpeg');
    expect(k1, k2);
    expect(store.fileFor(k1!)!.readAsBytesSync(), [1, 2]);
  });

  test('rejects oversize', () async {
    final k = await store.saveFromBytes(
        'x', List.filled(CoverStore.maxBytes + 1, 0), null);
    expect(k, isNull);
  });

  test('finds folder cover case-insensitively', () async {
    File(p.join(tmp.path, 'Folder.JPG')).writeAsBytesSync([1]);
    expect(await store.findFolderCover(tmp.path), isNotNull);
    expect(await store.findFolderCover(p.join(tmp.path, 'none')), isNull);
  });
}
