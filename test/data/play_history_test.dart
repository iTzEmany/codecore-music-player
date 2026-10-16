import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PlayHistoryRepository repo;
  late int trackId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PlayHistoryRepository(db);
    await db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/a.mp3', title: 'A', albumKey: 'k', format: 'mp3',
        sizeBytes: 1, mtimeMs: 1, addedAt: 1));
    trackId = (await db.select(db.tracks).getSingle()).id;
  });
  tearDown(() => db.close());

  test('start opens a row with the time and the context', () async {
    final id = await repo.start(trackId, 1000, context: 2, contextName: 'Mix', msPlayed: 30000);
    final row = (await db.select(db.plays).get()).single;
    expect(row.id, id);
    expect(row.trackId, trackId);
    expect(row.playedAt, 1000);
    expect(row.msPlayed, 30000);
    expect(row.context, 2);
    expect(row.contextName, 'Mix');
  });

  test('finish sets the time played; the last call wins', () async {
    final id = await repo.start(trackId, 1000);
    expect((await db.select(db.plays).getSingle()).msPlayed, 0);
    await repo.finish(id, 31000);
    await repo.finish(id, 42000);
    expect((await db.select(db.plays).getSingle()).msPlayed, 42000);
  });

  test('count counts the rows', () async {
    expect(await repo.count(), 0);
    await repo.start(trackId, 1);
    await repo.start(trackId, 2);
    expect(await repo.count(), 2);
  });
}
