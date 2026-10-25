import 'dart:io';

import 'package:codecore/services/online/download_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('add writes atomically: valid file, no .tmp left, reloadable', () async {
    final tmp = Directory.systemTemp.createTempSync('dl_idx');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final song = File(p.join(tmp.path, 's.m4a'))..writeAsStringSync('x');
    final file = File(p.join(tmp.path, 'downloads.json'));
    final idx = DownloadIndex(file);
    await Future.wait([for (var i = 0; i < 5; i++) idx.add('id$i', song.path)]);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
    final again = DownloadIndex(file);
    await again.load();
    expect(again.pathFor('id4'), song.path);
    expect(again.pathForKey('youtube:id0'), song.path);
  });
}
