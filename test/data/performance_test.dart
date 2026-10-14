import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic 20 000-track library: queries must stay interactive (docs fase 7.5).
void main() {
  late AppDatabase db;
  late TrackRepository repo;

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    final rows = <TracksCompanionRow>[];
    for (var i = 0; i < 20000; i++) {
      rows.add(TracksCompanionRow(i));
    }
    await db.batch((b) {
      b.insertAll(db.tracks, [for (final r in rows) r.toCompanion()]);
    });
  });
  tearDownAll(() => db.close());

  Future<int> timeMs(Future<Object?> Function() f) async {
    final sw = Stopwatch()..start();
    await f();
    return sw.elapsedMilliseconds;
  }

  test('list, search and sorts under budget', () async {
    expect(await repo.countAll(), 20000);
    final list = await timeMs(() => repo.watchTracks().first);
    final search = await timeMs(() => repo.watchTracks(query: 'song 19').first);
    final sorted = await timeMs(
        () => repo.watchTracks(sort: SortOption.artist).first);
    final albums = await timeMs(() => LibraryQueries(db).watchAlbums().first);
    final artists = await timeMs(() => LibraryQueries(db).watchArtists().first);
    // ignore: avoid_print
    print('perf ms: list=$list search=$search sorted=$sorted '
        'albums=$albums artists=$artists');
    expect(search, lessThan(250));
    expect(list, lessThan(1500));
    expect(sorted, lessThan(1500));
    expect(albums, lessThan(1000));
    expect(artists, lessThan(1000));
  });
}

class TracksCompanionRow {
  TracksCompanionRow(this.i);

  final int i;

  TracksCompanion toCompanion() => TracksCompanion.insert(
        path: '/m/${i % 500}/song $i.mp3',
        title: 'Song $i',
        albumKey: 'artist ${i % 500}|album ${i % 2000}',
        format: 'mp3',
        sizeBytes: 1000,
        mtimeMs: i,
        addedAt: i,
      );
}
