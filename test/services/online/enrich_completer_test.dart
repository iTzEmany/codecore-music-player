import 'dart:async';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/services/online/enrich_completer.dart';
import 'package:codecore/services/online/enrich_parts.dart' as parts_lib;
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:codecore/services/online/lrclib_client.dart';
import 'package:drift/drift.dart' show TableUpdateQuery, Value;
import 'package:flutter_test/flutter_test.dart';

import '../../support/enrich_fakes.dart';

const _lyrics = {EnrichPart.lyrics};
const _lyricsAndSynced = {EnrichPart.lyrics, EnrichPart.synced};
const _day = 24 * 3600 * 1000;

void main() {
  late EnrichRig r;
  var clock = DateTime.now().millisecondsSinceEpoch;
  var i = 0;

  setUp(() {
    r = EnrichRig();
    clock = DateTime.now().millisecondsSinceEpoch;
  });
  tearDown(() => r.dispose());

  Future<int> track({
    String? plain,
    String? synced,
    String? curiosities,
    int kind = 0,
    bool missing = false,
    bool ignored = false,
  }) => r.add(
    path: '/t${i++}.mp3',
    plain: plain,
    synced: synced,
    curiosities: curiosities,
    kind: kind,
    missing: missing,
    ignored: ignored,
  );

  Future<void> mark(
    int id, {
    int? lyrics,
    int? synced,
    int? curio,
    bool byUser = false,
  }) => r.db
      .into(r.db.trackEnrich)
      .insert(
        TrackEnrichCompanion(
          trackId: Value(id),
          lyricsNoneAt: Value(lyrics),
          syncedNoneAt: Value(synced),
          curioNoneAt: Value(curio),
          lyricsByUser: Value(byUser),
        ),
      );

  EnrichCompleter completer({
    Set<EnrichPart> parts = _lyrics,
    Future<void> Function()? idle,
    void Function(int, int)? progress,
  }) => EnrichCompleter(
    service: r.svc,
    repo: r.credits,
    parts: () => parts,
    waitIdle: idle ?? () async {},
    onProgress: progress,
    nowMs: () => clock,
  );

  group('run', () {
    test('a restarted completer carries on from the second track', () async {
      final ids = [for (var n = 0; n < 3; n++) await track()];
      final first = completer();
      r.chain.during = () async {
        if (r.chain.calls == 1) first.cancel();
      };
      final round1 = await first.run();
      expect(round1.worked, 1);
      expect(round1.updated[EnrichPart.lyrics], [ids[0]]);

      r.chain.during = null;
      final round2 = await completer().run();
      expect(round2.updated[EnrichPart.lyrics], [ids[1], ids[2]]);
      expect(r.chain.calls, 3); // the first was not asked again
    });

    test('nothing due, or no part on: no request and no wait', () async {
      await track(plain: 'a', synced: '[00:01.00]a');
      var idles = 0;
      final done = completer(
        parts: _lyricsAndSynced,
        idle: () async => idles++,
      );
      expect((await done.run()).worked, 0);

      await track(); // incomplete, but nothing is switched on
      final off = completer(parts: const {}, idle: () async => idles++);
      expect((await off.run()).worked, 0);
      expect(r.web.urls, isEmpty);
      expect([r.chain.calls, r.finder.calls, idles], [0, 0, 0]);
    });

    test('no track is worked while the user is busy', () async {
      await track();
      await track();
      final gate = Completer<void>();
      var idles = 0;
      final run = completer(
        idle: () {
          idles++;
          return gate.future;
        },
      ).run();
      await pumpEventQueue();
      expect(r.chain.calls, 0);
      gate.complete();
      expect((await run).worked, 2);
      expect(idles, 2); // before each track
    });

    test('25 tracks: 3 writes to the library, not 25', () async {
      for (var n = 0; n < 25; n++) {
        await track();
      }
      var writes = 0;
      final sub = r.db
          .tableUpdates(TableUpdateQuery.onTable(r.db.tracks))
          .listen((_) => writes++);
      final progress = <(int, int)>[];
      final round = await completer(progress: (c, t) => progress.add((c, t)))
          .run();
      await pumpEventQueue();
      await sub.cancel();
      expect(round.worked, 25);
      expect(writes, 3);
      expect(progress, [(10, 25), (20, 25), (25, 25)]);
    });

    test('25 tracks with cover and curiosities: still 3 writes', () async {
      final ids = [for (var n = 0; n < 25; n++) await track()];
      var writes = 0;
      final sub = r.db
          .tableUpdates(TableUpdateQuery.onTable(r.db.tracks))
          .listen((_) => writes++);
      final round = await completer(
        parts: {EnrichPart.meta, EnrichPart.lyrics, EnrichPart.curio},
      ).run();
      await pumpEventQueue();
      await sub.cancel();
      expect(round.updated[EnrichPart.curio], ids);
      expect(writes, 3);
      expect(r.web.bytes, 1); // one cover for the 25 of the album
      for (final t in await r.db.select(r.db.tracks).get()) {
        expect([t.hasCover, t.curiosities != null], [true, true]);
      }
    });

    test(
      'Deezer refuses: the text and the curiosities are saved anyway',
      () async {
        r.deezerMeta = true;
        r.web.deezerLimited = true;
        final id = await track();
        final round = await completer(
          parts: {...EnrichPart.values}..remove(EnrichPart.credits),
        ).run();
        final t = (await r.repo.getById(id))!;
        expect(t.lyricsPlain, 'la la');
        expect(t.curiosities, isNotNull);
        expect(round.updated[EnrichPart.lyrics], [id]);
        expect(round.updated[EnrichPart.curio], [id]);
        // A refusal is not «nothing» (invariant 3).
        expect(round.none[EnrichPart.meta], isNull);
        expect((await r.enrichOf(id))?.metaNoneAt, isNull);
      },
    );

    test(
      'a failed track is not asked again in the round, nor marked',
      () async {
        r.chain.failed = true;
        final ids = [for (var n = 0; n < 3; n++) await track()];
        final round = await completer().run();
        expect(r.chain.calls, 3);
        expect(round.updated, isEmpty);
        expect(round.none, isEmpty);
        for (final id in ids) {
          expect((await r.enrichOf(id))?.lyricsNoneAt, isNull);
        }
        await completer().run(); // a new round asks again
        expect(r.chain.calls, 6);
      },
    );

    test('a round counts what was updated and what had no text', () async {
      r.chain.resultFor = (t) => t.path.endsWith('${i - 1}.mp3')
          ? null
          : const LyricsResult(plain: 'x');
      final ids = [for (var n = 0; n < 3; n++) await track()];
      final round = await completer().run();
      expect(round.worked, 3);
      expect(round.updated[EnrichPart.lyrics], [ids[0], ids[1]]);
      expect(round.none[EnrichPart.lyrics], [ids[2]]);
      expect((await r.enrichOf(ids[2]))?.lyricsNoneAt, isNotNull);
      expect((await r.enrichOf(ids[0]))?.lyricsNoneAt, isNull);
    });

    test('a track whose write throws loses only itself', () async {
      final ids = [for (var n = 0; n < 10; n++) await track()];
      await r.db.customStatement(
        'CREATE TRIGGER boom BEFORE UPDATE ON tracks WHEN NEW.id = ${ids[4]} '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      final items = [for (final id in ids) await r.svc.gather(id, _lyrics)];
      final outs = await r.svc.commit(items);
      for (var n = 0; n < 10; n++) {
        final t = (await r.repo.getById(ids[n]))!;
        if (n == 4) {
          expect(outs[n][EnrichPart.lyrics], PartOutcome.failed);
          expect(t.lyricsPlain, isNull);
          expect((await r.enrichOf(ids[n]))?.lyricsNoneAt, isNull);
        } else {
          expect(outs[n][EnrichPart.lyrics], PartOutcome.found);
          expect(t.lyricsPlain, 'la la');
        }
      }
    });

    test('a part filled by another track of the block is left alone, not «nothing»', () async {
      // Same album, nothing but the cover missing: the first one's cover is the second's.
      Future<int> half() => r.add(
        path: '/h${i++}.mp3',
        album: 'Alb',
        genre: 'G',
        year: 2000,
        trackNumber: 1,
      );
      final a = await half(), b = await half();
      final items = [
        await r.svc.gather(a, {EnrichPart.meta}),
        await r.svc.gather(b, {EnrichPart.meta}),
      ];
      final outs = await r.svc.commit(items);
      expect(outs[0][EnrichPart.meta], PartOutcome.found);
      expect(outs[1][EnrichPart.meta], PartOutcome.skipped);
      expect((await r.repo.getById(b))!.hasCover, isTrue);
      expect((await r.enrichOf(b))?.metaNoneAt, isNull);
      expect((await r.repo.getById(b))!.enrichStatus, isNot(2));
    });

    test('curiosities written meanwhile are not replaced without force', () async {
      final id = await track();
      final g = await r.svc.gather(id, {EnrichPart.curio});
      await r.repo.setCuriosities(id, 'mine\nsrc');
      final outs = await r.svc.commit([g]);
      expect(outs.single[EnrichPart.curio], PartOutcome.skipped);
      expect((await r.repo.getById(id))!.curiosities, 'mine\nsrc');
      expect((await r.enrichOf(id))?.curioNoneAt, isNull);
    });

    test('now during a round in progress turns it into a now round', () async {
      await track();
      await track();
      final marked = await track();
      await mark(marked, lyrics: clock - _day);
      final c = completer(idle: () => Completer<void>().future);
      final plan = c.run();
      await pumpEventQueue();
      expect(r.chain.calls, 0); // waiting for the user
      expect(identical(c.run(now: true), plan), isTrue);
      expect(identical(c.run(), plan), isTrue);
      final round = await plan;
      expect(round.worked, 3); // also the «nothing» of yesterday
      expect(c.running, isFalse);
    });

    test('stop ends a wait for the user', () async {
      await track();
      final c = completer(idle: () => Completer<void>().future);
      final run = c.run();
      await pumpEventQueue();
      c.cancel();
      expect((await run).worked, 0);
      expect(r.chain.calls, 0);
      expect(c.running, isFalse);
    });

    test('a track gone while it was read is skipped', () async {
      final ids = [await track(), await track()];
      r.chain.during = () async {
        if (r.chain.calls == 1) {
          await (r.db.delete(
            r.db.tracks,
          )..where((t) => t.id.equals(ids[0]))).go();
        }
      };
      final round = await completer().run();
      expect(round.updated[EnrichPart.lyrics], [ids[1]]);
    });
  });

  group('now', () {
    late List<int> ids;
    setUp(() async {
      ids = [
        await track(plain: 'a', synced: '[00:01.00]a'),
        await track(plain: 'b', synced: '[00:01.00]b'),
        await track(), // «nothing» yesterday
        await track(),
        await track(),
      ];
      await mark(ids[2], lyrics: clock - _day);
    });

    test('works the 3 incomplete ones, even the «nothing» of yesterday, without waiting', () async {
      var idles = 0;
      final round = await completer(
        parts: _lyricsAndSynced,
        idle: () async => idles++,
      ).run(now: true);
      expect(round.worked, 3);
      expect(idles, 0);
      expect((await r.repo.getById(ids[2]))!.lyricsPlain, 'la la');
      expect((await r.enrichOf(ids[2]))?.lyricsNoneAt, isNull);
    });

    test(
      'the plan skips the «nothing» of yesterday and waits for the user',
      () async {
        var idles = 0;
        final round = await completer(
          parts: _lyricsAndSynced,
          idle: () async => idles++,
        ).run();
        expect(round.worked, 2);
        expect(idles, 2);
      },
    );

    test('stop: no track after the one in progress', () async {
      final c = completer(parts: _lyricsAndSynced);
      r.chain.during = () async {
        if (r.chain.calls == 2) c.cancel();
      };
      final round = await c.run(now: true);
      expect(round.worked, 2);
      expect(r.chain.calls, 2);
      expect(c.running, isFalse);
    });

    test('curiosities already there are not asked again', () async {
      await track(plain: 'a', curiosities: 'text\nsource');
      final c = completer(parts: {EnrichPart.curio});
      await c.run(now: true);
      // Only the 5 without a text: the sixth is complete.
      expect(r.finder.calls, 5);
    });
  });

  group('dueTrackIds', () {
    test('library and stream tracks only, not missing or hidden', () async {
      final music = await track();
      final stream = await track(kind: 2);
      await track(kind: 1);
      await track(missing: true);
      await track(ignored: true);
      expect(await r.credits.dueTrackIds(_lyrics, DateTime.now()), [
        music,
        stream,
      ]);
    });

    test('limit and exclude', () async {
      final ids = [for (var n = 0; n < 5; n++) await track()];
      expect(
        await r.credits.dueTrackIds(
          _lyrics,
          DateTime.now(),
          limit: 2,
          exclude: {ids[0]},
        ),
        [ids[1], ids[2]],
      );
    });

    test(
      'a «nothing» mark holds for 30 days, unless the marks are ignored',
      () async {
        final recent = await track();
        final old = await track();
        await mark(recent, lyrics: clock - 29 * _day);
        await mark(old, lyrics: clock - 31 * _day);
        final now = DateTime.fromMillisecondsSinceEpoch(clock);
        expect(await r.credits.dueTrackIds(_lyrics, now), [old]);
        expect(await r.credits.dueTrackIds(_lyrics, now, ignoreMarks: true), [
          recent,
          old,
        ]);
      },
    );

    test('the same answer as isDue for every combination', () async {
      final now = DateTime.fromMillisecondsSinceEpoch(clock);
      final noneAts = <int?>[null, clock - _day, clock - 40 * _day];
      for (final plain in [null, 'p']) {
        for (final synced in [null, 's']) {
          for (final curiosities in [null, 'c']) {
            for (final byUser in [false, true]) {
              for (final noneAt in noneAts) {
                final id = await track(
                  plain: plain,
                  synced: synced,
                  curiosities: curiosities,
                );
                await mark(
                  id,
                  lyrics: noneAt,
                  synced: noneAt,
                  curio: noneAt,
                  byUser: byUser,
                );
              }
            }
          }
        }
      }
      for (final part in [
        EnrichPart.lyrics,
        EnrichPart.synced,
        EnrichPart.curio,
      ]) {
        final all = await r.db.select(r.db.tracks).get();
        final expected = <int>[];
        for (final t in all) {
          if (parts_lib.isDue(part, t, await r.enrichOf(t.id), now)) {
            expected.add(t.id);
          }
        }
        final got = await r.credits.dueTrackIds({part}, now, limit: 1000);
        expect(got, expected, reason: '$part');
      }
    });

    test(
      'credits are due without credits rows, and meta without a cover',
      () async {
        final bare = await track();
        final withCredits = await track();
        await r.db
            .into(r.db.trackCredits)
            .insert(
              TrackCreditsCompanion.insert(
                trackId: withCredits,
                name: 'A',
                nameKey: 'a',
                role: 'composer',
                source: 'deezer',
              ),
            );
        expect(
          await r.credits.dueTrackIds({EnrichPart.credits}, DateTime.now()),
          [bare],
        );
        expect(await r.credits.dueTrackIds({EnrichPart.meta}, DateTime.now()), [
          bare,
          withCredits,
        ]);
      },
    );
  });

  test('counts: complete out of all, for the parts on', () async {
    await track(plain: 'a');
    await track(plain: 'b');
    await track();
    await track(kind: 1); // not counted
    final now = DateTime.fromMillisecondsSinceEpoch(clock);
    expect(await r.credits.enrichCounts(_lyrics, now), (complete: 2, total: 3));
    expect(await r.credits.enrichCounts(const {}, now), (
      complete: 3,
      total: 3,
    ));
  });
}
