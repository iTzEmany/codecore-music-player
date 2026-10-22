import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/review_queries.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ReviewQueries q;

  /// A track that is complete (nothing to review) unless a parameter says so.
  Future<int> add(
    String title, {
    int status = 1,
    int kind = 0,
    bool missing = false,
    bool ignored = false,
    String? lyrics = 'la la',
    bool cover = true,
    String? album = 'Album',
    int? year = 2000,
    String? genre = 'Rock',
  }) => db
      .into(db.tracks)
      .insert(
        TracksCompanion.insert(
          path: '/m/$title.mp3',
          title: title,
          albumKey: 'a|$title',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          enrichStatus: Value(status),
          kind: Value(kind),
          missing: Value(missing),
          ignored: Value(ignored),
          lyricsPlain: Value(lyrics),
          hasCover: Value(cover),
          album: Value(album),
          year: Value(year),
          genre: Value(genre),
        ),
      );

  Future<List<String>> titles({Set<int> dismissed = const {}}) async => [
    for (final t in await q.watch(dismissed: dismissed).first) t.title,
  ];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    q = ReviewQueries(db);
  });
  tearDown(() => db.close());

  test(
    'complete tracks and tracks never tried (status 0) are not listed',
    () async {
      await add('complete');
      await add('untried', status: 0, lyrics: null, cover: false, album: null);
      expect(await titles(), isEmpty);
    },
  );

  test('each reason lists the track and is reported', () async {
    await add('nothing', status: 2);
    await add('lyrics', lyrics: null);
    await add('cover', cover: false);
    await add('album', album: null);
    await add('year', year: null);
    await add('genre', genre: null);
    final rows = {for (final t in await q.watch().first) t.title: t};
    expect(
      rows.keys,
      containsAll(['nothing', 'lyrics', 'cover', 'album', 'year', 'genre']),
    );
    expect(reviewReasons(rows['nothing']!), {ReviewReason.nothingFound});
    expect(reviewReasons(rows['lyrics']!), {ReviewReason.noLyrics});
    expect(reviewReasons(rows['cover']!), {ReviewReason.noCover});
    expect(reviewReasons(rows['genre']!), {ReviewReason.missingData});
  });

  test('missing, hidden and episode rows are not listed', () async {
    await add('gone', status: 2, missing: true);
    await add('hidden', status: 2, ignored: true);
    await add('episode', status: 2, kind: 1);
    await add('kept', status: 2);
    expect(await titles(), ['kept']);
  });

  test('dismissed tracks are left out of the list and of the count', () async {
    final a = await add('a', status: 2);
    await add('b', status: 2);
    expect(await q.watchCount().first, 2);
    expect(await titles(dismissed: {a}), ['b']);
    expect(await q.watchCount(dismissed: {a}).first, 1);
  });
}
