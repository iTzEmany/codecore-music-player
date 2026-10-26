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
    scanner = LibraryScanner(
      reader,
      tracks,
      CoverStore(covers),
      useIsolate: false,
    );
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

  test(
    'first scan inserts, second does not re-read, delete -> missing',
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
      expect(
        (await db.select(db.tracks).get()).where((t) => t.missing),
        isEmpty,
      );
    },
  );

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
    reader.byName['x.mp3'] = const TagInfo(
      title: 'x',
      album: 'Solo',
      artist: 'Z',
    );
    final f1 = await folders.add(d.path);
    final f2 = await folders.add(other.path);
    await scanner.scan(f1).drain<void>();
    await scanner.scan(f2).drain<void>();
    expect(covers.listSync().length, 1);
    final rows = await db.select(db.tracks).get();
    expect(rows.where((t) => t.hasCover).length, 3);
    expect(rows.firstWhere((t) => t.title == 'x').hasCover, false);
  });

  test(
    'a replaced file (new size) is re-read and its duration updated',
    () async {
      final d = music();
      final folder = await folders.add(d.path);
      await scanner.scan(folder).drain<void>();
      final before = await (db.select(
        db.tracks,
      )..where((t) => t.title.equals('a.mp3'))).getSingle();
      expect(before.durationMs, 1000);

      reader.byName['a.mp3'] = const TagInfo(
        title: 'a.mp3',
        artist: 'Art',
        album: 'Alb',
        durationMs: 355000,
      );
      File(p.join(d.path, 'a.mp3')).writeAsBytesSync(List.filled(500, 1));
      reader.calls = 0;
      await scanner.scan(folder).drain<void>();
      expect(reader.calls, 1);
      final after = await (db.select(
        db.tracks,
      )..where((t) => t.title.equals('a.mp3'))).getSingle();
      expect(after.durationMs, 355000);
      expect(after.sizeBytes, 500);
    },
  );

  test('untagged file falls back to artist and title from its name', () async {
    final d = music();
    File(p.join(d.path, 'Art - Song (Lyrics).mp3')).writeAsBytesSync([0, 1]);
    final folder = await folders.add(d.path);
    await scanner.scan(folder).drain<void>();
    final all = await db.select(db.tracks).get();
    final t = all.firstWhere((t) => t.title == 'Song');
    expect(t.artist, 'Art');
    expect(all.firstWhere((t) => t.title == 'b.mp3').artist, 'Art'); // tagged
  });

  test('scan writes the ISRC of the tag when the track has none', () async {
    final d = music();
    reader.byName['a.mp3'] = const TagInfo(title: 'a', isrc: 'ITA123');
    final folder = await folders.add(d.path);
    await scanner.scan(folder).drain<void>();
    final all = await db.select(db.tracks).get();
    expect(all.firstWhere((t) => t.title == 'a').isrc, 'ITA123');
    expect(all.firstWhere((t) => t.title == 'b.mp3').isrc, isNull);
  });

  test('a rescan never overwrites an ISRC already on the track', () async {
    final d = music();
    reader.byName['a.mp3'] = const TagInfo(title: 'a', isrc: 'FIRST');
    final folder = await folders.add(d.path);
    await scanner.scan(folder).drain<void>();
    reader.byName['a.mp3'] = const TagInfo(title: 'a', isrc: 'OTHER');
    File(p.join(d.path, 'a.mp3')).writeAsBytesSync([0, 1, 2]);
    await scanner.scan(folder).drain<void>();
    expect(
      (await db.select(db.tracks).get()).firstWhere((t) => t.title == 'a').isrc,
      'FIRST',
    );
  });

  test('a rescan keeps a hand-picked cover and a new track of the album takes it', () async {
    final d = music();
    final folder = await folders.add(d.path);
    await scanner.scan(folder).drain<void>();
    await tracks.setManualAlbumCover(
        (await tracks.byPath(p.join(d.path, 'a.mp3')))!.albumKey, 'manual:album:k:1');
    final autoKey = CoverStore.coverKeyFor((await tracks.byPath(p.join(d.path, 'a.mp3')))!.albumKey);

    // a changed file and a new one
    File(p.join(d.path, 'a.mp3')).writeAsBytesSync(List.filled(500, 1));
    File(p.join(d.path, 'd.mp3')).writeAsBytesSync([0, 1]);
    reader.byName['d.mp3'] = const TagInfo(
        title: 'd', artist: 'Art', album: 'Alb', coverBytes: [1, 2, 3], coverMime: 'image/jpeg');
    await scanner.scan(folder).drain<void>();

    for (final n in ['a.mp3', 'd.mp3']) {
      final t = (await tracks.byPath(p.join(d.path, n)))!;
      expect([t.coverKey, t.coverSource], ['manual:album:k:1', 1], reason: n);
    }
    expect(autoKey, isNot('manual:album:k:1'));
  });
}
