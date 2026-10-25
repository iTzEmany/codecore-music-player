import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/credits_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TrackCreditsCompanion credit(String name, String role) => TrackCreditsCompanion.insert(
      trackId: 0,
      name: name,
      nameKey: name.toLowerCase(),
      role: role,
      source: 'deezer',
    );

void main() {
  late AppDatabase db;
  late CreditsRepository repo;
  late int id;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = CreditsRepository(db);
    id = await db.into(db.tracks).insert(TracksCompanion.insert(
        path: '/a.mp3', title: 'A', albumKey: 'y', format: 'mp3', sizeBytes: 1, mtimeMs: 1, addedAt: 1));
  });
  tearDown(() => db.close());

  test('credits are saved, read back and replaced by a new save', () async {
    await repo.saveCredits(id, [credit('Ann', 'composer'), credit('Bob', 'producer')]);
    expect((await repo.creditsOf(id)).map((c) => c.name).toSet(), {'Ann', 'Bob'});
    await repo.saveCredits(id, [credit('Cy', 'composer')]);
    expect((await repo.creditsOf(id)).map((c) => c.name), ['Cy']);
  });

  test('saveEnrich keeps the columns it does not set', () async {
    await repo.saveEnrich(TrackEnrichCompanion(trackId: Value(id), details: const Value('d'), deezerId: const Value(7)));
    await repo.saveEnrich(TrackEnrichCompanion(trackId: Value(id), mbid: const Value('m')));
    final e = (await repo.enrichOf(id))!;
    expect([e.details, e.deezerId, e.mbid], ['d', 7, 'm']);
  });

  test('combined save writes both; saveEnrich does not emit on watchTracks', () async {
    final tracks = TrackRepository(db);
    var emissions = 0;
    final sub = tracks.watchTracks().listen((_) => emissions++);
    await pumpEventQueue();
    final before = emissions;
    await repo.save(id, [credit('Ann', 'composer')], TrackEnrichCompanion(trackId: Value(id), creditsNoneAt: const Value(5)));
    await repo.saveEnrich(TrackEnrichCompanion(trackId: Value(id), deezerId: const Value(9)));
    await pumpEventQueue();
    expect(await repo.creditsOf(id), hasLength(1));
    expect((await repo.enrichOf(id))!.creditsNoneAt, 5);
    expect(emissions, before);
    await sub.cancel();
  });
}
