import 'package:codecore/core/import_row.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/services/import/import_diff.dart';
import 'package:flutter_test/flutter_test.dart';

PlaylistImportItem old(int i, String title, String artist,
        {String? isrc, int? track}) =>
    PlaylistImportItem(
        importId: 1,
        rowIndex: i,
        title: title,
        artists: artist,
        isrc: isrc,
        status: 2,
        trackId: track ?? i + 100);

ImportRow fresh(int i, String title, String artist, {String? isrc}) =>
    ImportRow(index: i, title: title, artists: [artist], isrc: isrc);

void main() {
  group('diffImport', () {
    test('added, removed and kept, with the new index of the kept ones', () {
      final d = diffImport([
        old(0, 'One', 'Band', isrc: 'I1'),
        old(1, 'Two', 'Band', isrc: 'I2'),
        old(2, 'Three', 'Band', isrc: 'I3'),
      ], [
        fresh(0, 'Three', 'Band', isrc: 'I3'),
        fresh(1, 'Four', 'Band', isrc: 'I4'),
        fresh(2, 'One', 'Band', isrc: 'I1'),
      ]);
      expect(d.added.map((r) => r.title), ['Four']);
      expect(d.removed.map((o) => o.title), ['Two']);
      expect([for (final k in d.kept) (k.old.title, k.fresh.index)],
          [('Three', 0), ('One', 2)]);
    });

    test('a changed ISRC with the same title and artist is still the same song',
        () {
      final d = diffImport([old(0, 'Imagine', 'John Lennon', isrc: 'OLD')],
          [fresh(0, 'Imagine', 'John Lennon', isrc: 'NEW')]);
      expect(d.kept, hasLength(1));
      expect(d.added, isEmpty);
      expect(d.removed, isEmpty);
    });

    test('remaster or feat. in the title does not split a song in two', () {
      final d = diffImport([old(0, 'Let It Be - Remastered 2009', 'The Beatles')],
          [fresh(0, 'Let It Be', 'The Beatles')]);
      expect(d.kept, hasLength(1));
    });

    test('the same song twice in the file matches two old items, one each', () {
      final d = diffImport([
        old(0, 'Echo', 'Band'),
        old(1, 'Echo', 'Band'),
      ], [
        fresh(0, 'Echo', 'Band'),
        fresh(1, 'Echo', 'Band'),
        fresh(2, 'Echo', 'Band'),
      ]);
      expect(d.kept, hasLength(2));
      expect(d.added, hasLength(1));
    });

    test('an identical file changes nothing', () {
      final d = diffImport([old(0, 'A', 'X', isrc: 'I'), old(1, 'B', 'X')],
          [fresh(0, 'A', 'X', isrc: 'I'), fresh(1, 'B', 'X')]);
      expect(d.added, isEmpty);
      expect(d.removed, isEmpty);
      expect(d.kept, hasLength(2));
    });

    test('an empty new file removes everything; an empty playlist adds everything',
        () {
      expect(diffImport([old(0, 'A', 'X')], const []).removed, hasLength(1));
      expect(diffImport(const [], [fresh(0, 'A', 'X')]).added, hasLength(1));
    });
  });

  group('reorderForSync', () {
    test('kept tracks follow the new file', () {
      expect(reorderForSync([1, 2, 3], {1: 2, 2: 0, 3: 1}), [2, 3, 1]);
    });

    test('a track added by hand stays after the one that preceded it', () {
      // 9 was put right after 1; 1 moves to the end, 9 goes with it.
      expect(reorderForSync([1, 9, 2, 3], {1: 2, 2: 0, 3: 1}), [2, 3, 1, 9]);
    });

    test('tracks at the very start stay at the start', () {
      expect(reorderForSync([8, 1, 2], {1: 1, 2: 0}), [8, 2, 1]);
    });

    test('nothing to move: the order is unchanged', () {
      expect(reorderForSync([1, 9, 2], {1: 0, 2: 1}), [1, 9, 2]);
      expect(reorderForSync([], {}), isEmpty);
      expect(reorderForSync([5, 6], {}), [5, 6]);
    });
  });
}
