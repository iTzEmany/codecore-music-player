import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/folder_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:codecore/services/scanner/library_scanner.dart';
import 'package:codecore/services/tags/tag_reader.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class FakeTagReader implements TagReader {
  int calls = 0;
  final Map<String, TagInfo> byName;
  FakeTagReader(this.byName);

  @override
  Future<TagInfo> read(String path, {bool withCover = true}) async {
    calls++;
    return byName[p.basename(path)] ?? const TagInfo();
  }
}

void main() {
  late Directory tmp;
  late Directory covers;
  late AppDatabase db;
  late TrackRepository tracks;
  late FolderRepository folders;
  late FakeTagReader reader;
  late LibraryScanner scanner;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('scan');
    covers = Directory(p.join(tmp.path, 'covers'));
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    folders = FolderRepository(db);
    reader = FakeTagReader({
      for (final n in ['a.mp3', 'b.mp3', 'c.mp3'])
        n: TagInfo(
          title: n,
          artist: 'Art',
          album: 'Alb',
          durationMs: 1000,
          coverBytes: const [1, 2, 3],
          coverMime: 'image/jpeg',
        ),
    });
    scanner = LibraryScanner(reader, tracks, CoverStore(covers),
        useIsolate: false);
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Directory music() {
    final d = Directory(p.join(tmp.path, 'music'))..createSync();
    for (final n in ['a.mp3', 'b.mp3', 'c.mp3']) {
      File(p.join(d.path, n)).writeAsBytesSync([0, 1]);
    }
    File(p.join(d.path, 'notes.txt')).writeAsStringSync('x');
    return d;
  }

  test('first scan inserts, second does not re-read, delete -> missing',
      () async {
    final d = music();
    final folder = await folders.add(d.path);
    await scanner.scan(folder).drain<void>();
    expect(await tracks.countAll(), 3);
    expect(reader.calls, 3);

    reader.calls = 0;
    await scanner.scan(folder).drain<void>();
    expect(reader.calls, 0);

    File(p.join(d.path, 'b.mp3')).deleteSync();
    await scanner.scan(folder).drain<void>();
    final all = await db.select(db.tracks).get();
    expect(all.firstWhere((t) => t.title == 'b.mp3').missing, true);
    expect(all.where((t) => t.missing).length, 1);

    File(p.join(d.path, 'b.mp3')).writeAsBytesSync([0, 1]);
    await scanner.scan(folder).drain<void>();
    expect((await db.select(db.tracks).get()).where((t) => t.missing), isEmpty);
  });

  test('missing root does not mark anything', () async {
    final d = music();
    final folder = await folders.add(d.path);
    await scanner.scan(folder).drain<void>();
    d.deleteSync(recursive: true);
    final events = await scanner.scan(folder).toList();
    expect(events.single.failed, true);
    expect((await db.select(db.tracks).get()).where((t) => t.missing), isEmpty);
  });

  test('one album -> one cover file; no cover -> hasCover false', () async {
    final d = music();
    final other = Directory(p.join(tmp.path, 'other'))..createSync();
    File(p.join(other.path, 'x.mp3')).writeAsBytesSync([0]);
    reader.byName['x.mp3'] = const TagInfo(title: 'x', album: 'Solo', artist: 'Z');
    final f1 = await folders.add(d.path);
    final f2 = await folders.add(other.path);
    await scanner.scan(f1).drain<void>();
    await scanner.scan(f2).drain<void>();
    expect(covers.listSync().length, 1);
    final rows = await db.select(db.tracks).get();
    expect(rows.where((t) => t.hasCover).length, 3);
    expect(rows.firstWhere((t) => t.title == 'x').hasCover, false);
  });
}
