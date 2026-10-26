import 'package:codecore/services/online/credits.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/credits_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TrackCreditsCompanion credit(String name, String role) =>
    TrackCreditsCompanion.insert(
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
    id = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/a.mp3',
            title: 'A',
            albumKey: 'y',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
          ),
        );
  });
  tearDown(() => db.close());

  test('credits are saved, read back and replaced by a new save', () async {
    await repo.saveCredits(id, [
      credit('Ann', 'composer'),
      credit('Bob', 'producer'),
    ]);
    expect((await repo.creditsOf(id)).map((c) => c.name).toSet(), {
      'Ann',
      'Bob',
    });
    await repo.saveCredits(id, [credit('Cy', 'composer')]);
    expect((await repo.creditsOf(id)).map((c) => c.name), ['Cy']);
  });

  test('watchPortableOf emits again when credits are saved', () async {
    final seen = <int>[];
    final sub = repo.watchPortableOf(id).listen((d) => seen.add(d.credits.length));
    await pumpEventQueue();
    await repo.saveCredits(id, [credit('Ann', 'composer')]);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });

  test('watchCreditedTracks emits again with the track once credited', () async {
    final seen = <List<int>>[];
    final sub = repo
        .watchCreditedTracks('ann')
        .listen((r) => seen.add([for (final e in r) e.track.id]));
    await pumpEventQueue();
    await repo.saveCredits(id, [credit('Ann', 'composer')]);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, isEmpty);
    expect(seen.last, [id]);
  });

  test('saveEnrich keeps the columns it does not set', () async {
    await repo.saveEnrich(
      TrackEnrichCompanion(
        trackId: Value(id),
        details: const Value('d'),
        deezerId: const Value(7),
      ),
    );
    await repo.saveEnrich(
      TrackEnrichCompanion(trackId: Value(id), mbid: const Value('m')),
    );
    final e = (await repo.enrichOf(id))!;
    expect([e.details, e.deezerId, e.mbid], ['d', 7, 'm']);
  });

  test(
    'combined save writes both; saveEnrich does not emit on watchTracks',
    () async {
      final tracks = TrackRepository(db);
      var emissions = 0;
      final sub = tracks.watchTracks().listen((_) => emissions++);
      await pumpEventQueue();
      final before = emissions;
      await repo.save(
        id,
        [credit('Ann', 'composer')],
        TrackEnrichCompanion(trackId: Value(id), creditsNoneAt: const Value(5)),
      );
      await repo.saveEnrich(
        TrackEnrichCompanion(trackId: Value(id), deezerId: const Value(9)),
      );
      await pumpEventQueue();
      expect(await repo.creditsOf(id), hasLength(1));
      expect((await repo.enrichOf(id))!.creditsNoneAt, 5);
      expect(emissions, before);
      await sub.cancel();
    },
  );

  test('creditedTracks: one entry per role, only library tracks', () async {
    Future<int> add(String t, int kind) => db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/$t.mp3',
            title: t,
            albumKey: 'y',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: 1,
            kind: Value(kind),
          ),
        );
    final a = await add('A1', 0),
        b = await add('B1', 0),
        s = await add('S1', 2);
    await repo.saveCredits(a, [
      credit('Pharrell', 'producer'),
      credit('Pharrell', 'composer'),
    ]);
    await repo.saveCredits(b, [credit('Pharrell', 'producer')]);
    await repo.saveCredits(s, [credit('Pharrell', 'producer')]);
    final r = await repo.creditedTracks('pharrell');
    expect(
      [for (final e in r) (e.role, e.track.title)],
      [('composer', 'A1'), ('producer', 'A1'), ('producer', 'B1')],
    );
    expect(await repo.creditedTracks('nobody'), isEmpty);
  });

  Future<int> addTrack(String t, {bool ignored = false}) => db
      .into(db.tracks)
      .insert(
        TracksCompanion.insert(
          path: '/$t.mp3',
          title: t,
          albumKey: 'y',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          ignored: Value(ignored),
        ),
      );

  test('portableOfMany: an id repeated across chunks counts once', () async {
    await repo.saveCredits(id, [credit('Ann', 'composer')]);
    final ids = [id, for (var i = 0; i < 600; i++) 100000 + i, id];
    expect((await repo.portableOfMany(ids))[id]!.credits, hasLength(1));
  });

  test('moveInto: keeper with the none mark and no credits takes the drop credits, mark cleared', () async {
    final drop = await addTrack('D');
    await repo.saveEnrich(
      TrackEnrichCompanion(trackId: Value(id), creditsNoneAt: const Value(5)),
    );
    await repo.saveCredits(drop, [credit('Ann', 'composer')]);
    await repo.moveInto(id, {drop});
    expect(await repo.creditsOf(id), hasLength(1));
    expect((await repo.enrichOf(id))!.creditsNoneAt, isNull);
  });

  test('saveIfNone: unreadable stored details are replaced; the none mark is cleared by credits', () async {
    await repo.saveEnrich(
      TrackEnrichCompanion(
        trackId: Value(id),
        details: const Value('{broken'),
        creditsNoneAt: const Value(5),
      ),
    );
    await repo.saveIfNone(id, [
      TrackCredit('Ann', 'composer', 'deezer'),
    ], const TrackDetails(label: 'L'));
    expect((await repo.portableOf(id)).details!.label, 'L');
    expect((await repo.enrichOf(id))!.creditsNoneAt, isNull);
  });

  test('creditedTracks leaves out an ignored track', () async {
    final x = await addTrack('X', ignored: true);
    await repo.saveCredits(x, [credit('Pharrell', 'producer')]);
    expect(await repo.creditedTracks('pharrell'), isEmpty);
  });

  test(
    'creditedTracks prefix: not a substring, no duplicates, exclude, limit',
    () async {
      final ids = [
        for (final t in ['T1', 'T2', 'T3']) await addTrack(t),
      ];
      await repo.saveCredits(ids[0], [
        credit('Pharrell', 'producer'),
        credit('Pharrell', 'composer'),
      ]);
      await repo.saveCredits(ids[1], [credit('Pharrell W', 'producer')]);
      await repo.saveCredits(ids[2], [credit('Not Pharrell', 'producer')]);
      List<String> titles(List<({String role, Track track})> r) => [
        for (final e in r) e.track.title,
      ];
      expect(titles(await repo.creditedTracks('pharrell', prefix: true)), [
        'T1',
        'T2',
      ]);
      expect(
        titles(
          await repo.creditedTracks(
            'pharrell',
            prefix: true,
            exclude: {ids[0]},
          ),
        ),
        ['T2'],
      );
      expect(
        titles(
          await repo.creditedTracks(
            'pharrell',
            prefix: true,
            exclude: {ids[0]},
            limit: 1,
          ),
        ),
        ['T2'],
      );
      expect(
        titles(await repo.creditedTracks('pharrell', prefix: true, limit: 1)),
        ['T1'],
      );
    },
  );

  test('decodeDetails: valid JSON that is not a map gives null', () {
    for (final raw in ['[]', 'null', '1', '{broken']) {
      expect(decodeDetails(1, raw), isNull);
    }
  });
}
