import 'dart:io';
import 'dart:typed_data';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/duplicate_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/library/duplicate_finder.dart';
import 'package:codecore/services/library/file_hasher.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

DupEntry entry(
  int id,
  String title,
  String artist, {
  int durationMs = 200000,
  String format = 'mp3',
  int? bitrate = 128,
  int size = 1000,
  String? path,
  bool cover = false,
  bool edited = false,
  int added = 1,
  String? sha,
}) => DupEntry(
  id: id,
  path: path ?? '/m/$id.$format',
  title: title,
  artist: artist,
  durationMs: durationMs,
  format: format,
  sizeBytes: size,
  bitrateKbps: bitrate,
  hasCover: cover,
  userEdited: edited,
  addedAt: added,
  sha256: sha,
);

List<List<int>> ids(List<DuplicateGroup> gs) => [
  for (final g in gs) (g.members.map((m) => m.id).toList()..sort()),
];

void main() {
  group('findDuplicates', () {
    test('the same song as mp3 128 k and flac is a probable group, the flac proposed', () {
      final mp3 = entry(1, 'Bohemian Rhapsody', 'Queen', durationMs: 354000, size: 5000);
      final flac = entry(2, 'Bohemian Rhapsody', 'Queen',
          durationMs: 354500, format: 'flac', bitrate: 900, size: 30000);
      final groups = findDuplicates([mp3, flac]);
      expect(groups, hasLength(1));
      expect(groups.single.exact, isFalse);
      expect(groups.single.proposed.id, 2);
      expect(groups.single.members.map((m) => m.id), [2, 1]);
    });

    test('qualifiers and feat. do not split a song; the artist is the main one', () {
      final groups = findDuplicates([
        entry(1, 'Song (2011 Remaster)', 'Band feat. Guest'),
        entry(2, 'Song', 'Band'),
        entry(3, 'Song - Radio Edit', 'Band, Other'),
      ]);
      expect(ids(groups), [[1, 2, 3]]);
    });

    test('same title and artist but lengths further apart than 2 s are two songs', () {
      final groups = findDuplicates([
        entry(1, 'Intro', 'Band', durationMs: 60000),
        entry(2, 'Intro', 'Band', durationMs: 75000),
      ]);
      expect(groups, isEmpty);
    });

    test('lengths are chained: 100.0, 101.9 and 103.8 s are one group', () {
      final groups = findDuplicates([
        entry(1, 'A', 'B', durationMs: 100000),
        entry(2, 'A', 'B', durationMs: 101900),
        entry(3, 'A', 'B', durationMs: 103800),
        entry(4, 'A', 'B', durationMs: 120000),
      ]);
      expect(ids(groups), [[1, 2, 3]]);
    });

    test('«Intro» of different albums by different artists is not a duplicate', () {
      expect(
        findDuplicates([
          entry(1, 'Intro', 'Artist One', durationMs: 60000),
          entry(2, 'Intro', 'Artist Two', durationMs: 60000),
        ]),
        isEmpty,
      );
    });

    test('a track without title or artist is never joined by name', () {
      expect(
        findDuplicates([
          entry(1, 'Track 01', '', durationMs: 60000),
          entry(2, 'Track 01', '', durationMs: 60000),
          entry(3, '', 'Band', durationMs: 60000),
          entry(4, '', 'Band', durationMs: 60000),
        ]),
        isEmpty,
      );
    });

    test('equal hashes are an exact group even with different names', () {
      final groups = findDuplicates(
        [
          entry(1, 'One', 'A', path: '/a/one.mp3'),
          entry(2, 'Two', 'B', path: '/b/two.mp3'),
          entry(3, 'Three', 'C'),
        ],
        hashes: {1: 'h', 2: 'h', 3: 'x'},
      );
      expect(ids(groups), [[1, 2]]);
      expect(groups.single.exact, isTrue);
    });

    test('a group with a copy and another version is not exact, and joins all three', () {
      final groups = findDuplicates(
        [
          entry(1, 'Song', 'Band', size: 5000, sha: 'h'),
          entry(2, 'Song', 'Band', size: 5000, sha: 'h'),
          entry(3, 'Song', 'Band', format: 'flac', bitrate: 900, size: 30000),
        ],
      );
      expect(ids(groups), [[1, 2, 3]]);
      expect(groups.single.exact, isFalse);
      expect(groups.single.proposed.id, 3);
    });

    test('exact groups come first', () {
      final groups = findDuplicates(
        [
          entry(1, 'Aaa', 'X', sha: 'p'),
          entry(2, 'Aaa', 'X', format: 'flac'),
          entry(3, 'Zzz', 'Y', sha: 'q'),
          entry(4, 'Zzz', 'Y', sha: 'q'),
        ],
      );
      expect(groups.map((g) => g.exact), [true, false]);
    });

    test('the group key does not depend on the order of the members', () {
      final a = findDuplicates([entry(1, 'S', 'B'), entry(2, 'S', 'B')]).single;
      final b = findDuplicates([entry(2, 'S', 'B'), entry(1, 'S', 'B')]).single;
      expect(a.key, b.key);
      expect(a.key, '1,2');
    });
  });

  group('the version proposed to keep', () {
    int keeper(List<DupEntry> group) => findDuplicates(group).single.proposed.id;

    test('lossless beats a higher-bitrate lossy file', () {
      expect(keeper([entry(1, 'S', 'B', bitrate: 320), entry(2, 'S', 'B', format: 'flac', bitrate: null)]), 2);
    });

    test('then bitrate, then edited, then cover, then the oldest', () {
      expect(keeper([entry(1, 'S', 'B', bitrate: 128), entry(2, 'S', 'B', bitrate: 256)]), 2);
      expect(keeper([entry(1, 'S', 'B'), entry(2, 'S', 'B', edited: true)]), 2);
      expect(keeper([entry(1, 'S', 'B'), entry(2, 'S', 'B', cover: true)]), 2);
      expect(keeper([entry(1, 'S', 'B', added: 20), entry(2, 'S', 'B', added: 10)]), 2);
      expect(keeper([entry(5, 'S', 'B'), entry(4, 'S', 'B')]), 4);
    });
  });

  group('hashCandidates', () {
    test('only tracks that share a size with another and have no hash', () {
      final lib = [
        entry(1, 'A', 'x', size: 100),
        entry(2, 'B', 'x', size: 100),
        entry(3, 'C', 'x', size: 200),
        entry(4, 'D', 'x', size: 300, sha: 'cached'),
        entry(5, 'E', 'x', size: 300),
        entry(6, 'F', 'x', size: 0),
        entry(7, 'G', 'x', size: 0),
      ];
      expect(hashCandidates(lib).map((e) => e.id), [1, 2, 5]);
    });
  });

  group('hashing real files', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('dups'));
    tearDown(() => dir.deleteSync(recursive: true));

    Future<String> write(String sub, String name, List<int> bytes) async {
      final f = File(p.join(dir.path, sub, name));
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes);
      return f.path;
    }

    test('the same file in two folders is an exact group, a different one of the same size is not', () async {
      final bytes = Uint8List.fromList(List.generate(5000, (i) => i % 251));
      final other = Uint8List.fromList(List.generate(5000, (i) => (i * 7) % 251));
      final a = await write('one', 'song.mp3', bytes);
      final b = await write('copy', 'song.mp3', bytes);
      final c = await write('one', 'same_size_other.mp3', other);
      final lone = await write('one', 'lonely.mp3', [1, 2, 3]);
      final lib = [
        entry(1, 'Song', 'Band', path: a, size: 5000),
        entry(2, 'Song', 'Band', path: b, size: 5000),
        entry(3, 'Other', 'Band', path: c, size: 5000),
        entry(4, 'Lonely', 'Band', path: lone, size: 3),
      ];

      final progress = <(int, int)>[];
      final hashes = await hashDuplicateCandidates(lib, onProgress: (d, t) => progress.add((d, t)));

      expect(hashes.keys, unorderedEquals([1, 2, 3]), reason: 'the lonely size is never read');
      expect(hashes[1], hashes[2]);
      expect(hashes[3], isNot(hashes[1]));
      expect(hashes[1], hasLength(64));
      expect(progress.last, (3, 3));

      final groups = findDuplicates(lib, hashes: hashes);
      expect(ids(groups), [[1, 2]]);
      expect(groups.single.exact, isTrue);
    });

    test('an unreadable file is skipped, the others are hashed, and cancelling stops early', () async {
      final a = await write('x', 'a.mp3', [1, 2, 3, 4]);
      final b = await write('y', 'b.mp3', [1, 2, 3, 4]);
      final lib = [
        entry(1, 'A', 'x', path: a, size: 4),
        entry(2, 'B', 'x', path: b, size: 4),
        entry(3, 'C', 'x', path: p.join(dir.path, 'gone.mp3'), size: 4),
      ];
      final hashes = await hashDuplicateCandidates(lib);
      expect(hashes.keys, unorderedEquals([1, 2]));

      var polls = 0;
      final stopped = await hashDuplicateCandidates(lib, isCancelled: () => ++polls > 1);
      expect(stopped.keys, hasLength(1));
    });

    test('a hasher that is injected replaces the disk read', () async {
      final lib = [entry(1, 'A', 'x', size: 4), entry(2, 'B', 'x', size: 4)];
      final hashes = await hashDuplicateCandidates(lib, hasher: (path) async => 'fake:$path');
      expect(hashes[1], 'fake:/m/1.mp3');
    });
  });

  group('DuplicateRepository', () {
    late AppDatabase db;
    late TrackRepository tracks;
    late DuplicateRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      tracks = TrackRepository(db);
      repo = DuplicateRepository(db);
    });
    tearDown(() => db.close());

    TracksCompanion row(String path, {int size = 10, int mtime = 1}) => TracksCompanion.insert(
      path: path,
      title: 'T',
      albumKey: 'k',
      format: 'mp3',
      sizeBytes: size,
      mtimeMs: mtime,
      addedAt: 1,
      artist: const Value('A'),
    );

    test('entries lists visible tracks only and carries the saved hash', () async {
      await tracks.upsertBatch([row('/a.mp3'), row('/b.mp3'), row('/c.mp3')]);
      final b = (await tracks.idForPath('/b.mp3'))!;
      final c = (await tracks.idForPath('/c.mp3'))!;
      await tracks.setIgnored({b}, true);
      await tracks.markMissing({'/c.mp3'}, true);
      final a = (await tracks.idForPath('/a.mp3'))!;
      await repo.saveHashes({a: 'abc'});

      final entries = await repo.entries();
      expect(entries.map((e) => e.id), [a]);
      expect(entries.single.sha256, 'abc');
      expect(entries.single.artist, 'A');
      expect(c, isNot(a));
    });

    test('a rescan keeps the hash while size and time are the same and drops it when they change', () async {
      await tracks.upsertBatch([row('/a.mp3')]);
      final id = (await tracks.idForPath('/a.mp3'))!;
      await repo.saveHashes({id: 'abc'});

      await tracks.upsertBatch([row('/a.mp3')]);
      expect((await repo.entries()).single.sha256, 'abc');

      await tracks.upsertBatch([row('/a.mp3', mtime: 2)]);
      expect((await repo.entries()).single.sha256, isNull);

      await repo.saveHashes({id: 'def'});
      await tracks.upsertBatch([row('/a.mp3', mtime: 2, size: 11)]);
      expect((await repo.entries()).single.sha256, isNull);
    });
  });

  test('20 000 tracks with 500 synthetic duplicates are searched in under a second', () {
    final margin = int.tryParse(Platform.environment['CODECORE_PERF_MARGIN'] ?? '') ?? 2;
    final lib = <DupEntry>[
      for (var i = 0; i < 20000; i++)
        entry(i, 'Song number $i (Remastered 2011)', 'Artist ${i % 1500} feat. Guest',
            durationMs: 180000 + (i % 97) * 1000, size: 1000 + i),
      for (var i = 0; i < 500; i++)
        entry(100000 + i, 'Song number ${i * 7}', 'Artist ${(i * 7) % 1500}',
            durationMs: 180000 + ((i * 7) % 97) * 1000 + 300, format: 'flac', size: 900000 + i),
    ];
    final sw = Stopwatch()..start();
    final groups = findDuplicates(lib);
    sw.stop();
    expect(groups, hasLength(500));
    expect(groups.every((g) => g.proposed.format == 'flac'), isTrue);
    expect(sw.elapsedMilliseconds, lessThan(1000 * margin), reason: '${sw.elapsedMilliseconds} ms');
  });
}
