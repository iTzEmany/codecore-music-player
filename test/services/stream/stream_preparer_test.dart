import 'dart:async';
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/stream/stream_cache.dart';
import 'package:codecore/services/stream/stream_preparer.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Writes a file per download; each one ends when its gate is opened.
/// streamRow waits for [gate], so a ready() on a cached file stays in flight.
class _SlowTracks extends TrackRepository {
  _SlowTracks(super.db);
  final gate = Completer<void>();
  @override
  Future<Track?> streamRow(String key) => gate.future.then((_) => super.streamRow(key));
}

class _Yt implements YoutubeService {
  final started = <String>[];
  final failuresLeft = <String, int>{};
  final rateLimits = <String, int>{};
  final forbidden = <String, int>{};
  final _gates = <String, Completer<void>>{};
  var open = 0, maxOpen = 0;
  var autoFinish = false;
  final tokens = <String, List<CancelToken?>>{};
  final dirs = <String, List<String>>{};

  void finish(String id) => _gates[id]!.complete();

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
      {CancelToken? cancel, DownloadOptions options = const DownloadOptions()}) async* {
    started.add(r.id);
    (tokens[r.id] ??= []).add(cancel);
    (dirs[r.id] ??= []).add(outDir.path);
    maxOpen = ++open > maxOpen ? open : maxOpen;
    try {
      final gate = _gates[r.id] = Completer<void>();
      if (autoFinish) gate.complete();
      unawaited(cancel?.whenCancel.then((_) {
        if (!gate.isCompleted) gate.completeError(StateError('cancelled'));
      }));
      await gate.future;
      if ((rateLimits[r.id] ?? 0) > 0) {
        rateLimits[r.id] = rateLimits[r.id]! - 1;
        throw const YtException(YtErrorKind.rateLimited, '429');
      }
      if ((forbidden[r.id] ?? 0) > 0) {
        forbidden[r.id] = forbidden[r.id]! - 1;
        throw const YtException(YtErrorKind.network, 'HTTP Error 403');
      }
      if ((failuresLeft[r.id] ?? 0) > 0) {
        failuresLeft[r.id] = failuresLeft[r.id]! - 1;
        throw const YtException(YtErrorKind.network, 'boom');
      }
      await outDir.create(recursive: true);
      final f = File(p.join(outDir.path, 'Some title - ${r.id}.m4a'))..writeAsBytesSync([1, 2, 3]);
      yield DownloadProgress(path: f.path);
    } finally {
      open--;
    }
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

YtResult _r(String id) => YtResult(id: id, title: 'T $id', channel: 'C', duration: null);
StreamItem _i(String id) => StreamItem('youtube:$id', _r(id));
/// Polls until [cond] holds (2 s at most).
Future<void> _until(bool Function() cond) async {
  final end = DateTime.now().add(const Duration(seconds: 2));
  while (!cond()) {
    if (DateTime.now().isAfter(end)) fail('condition not reached in 2 s');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// Lets the scheduler run, to prove nothing else starts.
Future<void> _quiet() => Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  late Directory root;
  late AppDatabase db;
  late TrackRepository tracks;
  late StreamCache cache;
  late _Yt yt;
  var metered = false;
  StreamEnricher? enrich;
  late StreamPreparer prep;

  StreamPreparer make({
    Duration cooldown = const Duration(minutes: 5),
    Duration attemptTimeout = const Duration(minutes: 5),
  }) =>
      prep = StreamPreparer(
        attemptTimeout: attemptTimeout,
        cache: cache,
        tracks: tracks,
        youtube: yt,
        isMetered: () async => metered,
        enrich: enrich,
        cooldown: cooldown,
      );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('preparer');
    db = AppDatabase(NativeDatabase.memory());
    tracks = TrackRepository(db);
    cache = StreamCache(Directory(p.join(root.path, 'c')), freeSpace: () async => null);
    await cache.open();
    yt = _Yt();
    metered = false;
    enrich = null;
    make();
  });
  tearDown(() async {
    prep.dispose();
    await db.close();
    await root.delete(recursive: true);
  });

  test('4 queued tracks: never more than 2 downloads, in queue order', () async {
    prep.setQueue([for (final n in ['a', 'b', 'c', 'd']) _i(n)]);
    await _until(() => yt.started.length == 2);
    await _quiet();
    expect(yt.started, ['a', 'b']);
    yt.finish('a');
    await _until(() => yt.started.length == 3);
    yt.finish('b');
    await _until(() => yt.started.length == 4);
    yt.finish('c');
    yt.finish('d');
    await _until(() => prep.phases.value.length == 4 && prep.phases.value.values.every((v) => v == StreamPhase.ready));
    expect(yt.started, ['a', 'b', 'c', 'd']);
    expect(yt.maxOpen, 2);
  });

  test('metered network and 10 tracks: only the next 3 are prepared', () async {
    metered = true;
    yt.autoFinish = true;
    prep.setQueue([for (var n = 0; n < 10; n++) _i('$n')]);
    await _until(() => yt.started.length >= 3);
    await _quiet();
    expect(yt.started, ['0', '1', '2']);
  });

  test('a user pick on a metered network is prepared even out of the window', () async {
    metered = true;
    yt.autoFinish = true;
    final f = await prep.ready('youtube:z', _r('z'));
    expect(p.basename(f.path), 'youtube_z.m4a');
    expect(await tracks.streamRow('youtube:z'), isNotNull);
  });

  test('a download failing twice: one retry, then ready throws', () async {
    yt.autoFinish = true;
    yt.failuresLeft['bad'] = 2;
    await expectLater(prep.ready('youtube:bad', _r('bad')), throwsA(isA<YtException>()));
    expect(yt.started, ['bad', 'bad']);
    expect(prep.phases.value['youtube:bad'], StreamPhase.failed);
  });

  test('one failure is retried and succeeds', () async {
    yt.autoFinish = true;
    yt.failuresLeft['flaky'] = 1;
    await prep.ready('youtube:flaky', _r('flaky'));
    expect(yt.started, ['flaky', 'flaky']);
  });

  test('two requests for the same key start one download', () async {
    yt.autoFinish = true;
    prep.setQueue([_i('a')]);
    final both = await Future.wait([
      prep.ready('youtube:a', _r('a')),
      prep.ready('youtube:a', _r('a')),
    ]);
    expect(both[0].path, both[1].path);
    expect(yt.started, ['a']);
  });

  test('ready resolves before a slow enrichment ends; then the row has its text', () async {
    final gate = Completer<void>();
    enrich = (r, rowId) async {
      await gate.future;
      final id = await rowId;
      await (db.update(db.tracks)..where((t) => t.id.equals(id)))
          .write(const TracksCompanion(lyricsPlain: Value('la la')));
    };
    make();
    yt.autoFinish = true;
    await prep.ready('youtube:a', _r('a'));
    expect((await tracks.streamRow('youtube:a'))!.lyricsPlain, isNull);
    gate.complete();
    for (var n = 0; n < 200; n++) {
      if ((await tracks.streamRow('youtube:a'))!.lyricsPlain != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect((await tracks.streamRow('youtube:a'))!.lyricsPlain, 'la la');
  });

  test('an enrichment that throws does not fail ready', () async {
    enrich = (r, rowId) async => throw StateError('lyrics down');
    make();
    yt.autoFinish = true;
    await prep.ready('youtube:a', _r('a'));
  });

  test('prefetch hit by a 429 pauses, then is retried without failing', () async {
    make(cooldown: const Duration(milliseconds: 50));
    yt.autoFinish = true;
    yt.rateLimits['a'] = 1;
    prep.setQueue([_i('a')]);
    await _until(() => prep.phases.value['youtube:a'] == StreamPhase.ready);
    expect(yt.started, ['a', 'a']);
  });

  test('a 429 under a waiting ready() is a failed attempt: retry once, then error', () async {
    yt.autoFinish = true;
    yt.rateLimits['a'] = 1;
    await prep.ready('youtube:a', _r('a'));
    expect(yt.started, ['a', 'a']);
    yt.rateLimits['b'] = 2;
    await expectLater(prep.ready('youtube:b', _r('b')), throwsA(isA<YtException>()));
    expect(yt.started, ['a', 'a', 'b', 'b']);
  });

  test('a failed key is downloaded again by the next ready()', () async {
    yt.autoFinish = true;
    yt.failuresLeft['x'] = 2;
    await expectLater(prep.ready('youtube:x', _r('x')), throwsA(isA<YtException>()));
    await prep.ready('youtube:x', _r('x'));
    expect(yt.started, ['x', 'x', 'x']);
  });

  test('ready() on a key already downloading starts no second download', () async {
    prep.setQueue([_i('a')]);
    await _until(() => yt.started.contains('a'));
    final f = prep.ready('youtube:a', _r('a'));
    yt.finish('a');
    await f;
    expect(yt.started, ['a']);
  });

  test('requested jobs start in queue order: after fast skipping the current one is first', () async {
    prep.setQueue([for (final n in ['w', 'x', 'c', 'd']) _i(n)]);
    await _until(() => yt.started.length == 2);
    // Both slots are held by requested jobs; the user then skipped to d, back to c.
    final w = prep.ready('youtube:w', _r('w'));
    final x = prep.ready('youtube:x', _r('x'));
    final d = prep.ready('youtube:d', _r('d'));
    final c = prep.ready('youtube:c', _r('c'));
    yt.finish('w');
    await _until(() => yt.started.length == 3);
    expect(yt.started[2], 'c');
    yt.finish('x');
    await _until(() => yt.started.length == 4);
    yt.finish('c');
    yt.finish('d');
    await Future.wait([w, x, c, d]);
  });

  test('a user pick starts at once even when prefetches hold every slot', () async {
    prep.setQueue([_i('a'), _i('b')]);
    await _until(() => yt.started.length == 2);
    final z = prep.ready('youtube:z', _r('z'));
    await _until(() => yt.started.length == 3);
    expect(yt.started, ['a', 'b', 'z']);
    yt.finish('z');
    await z;
  });

  test('unmetered prefetch stops at a full cache and never evicts what it downloaded', () async {
    cache.limitBytes = 10; // 3-byte files
    yt.autoFinish = true;
    prep.setQueue([for (final n in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']) _i(n)]);
    await _quiet();
    await _quiet();
    expect(yt.started.length, lessThan(8));
    for (final id in yt.started) {
      expect(await cache.fileFor('youtube:$id'), isNotNull, reason: id);
    }
    expect(yt.started.take(3), ['a', 'b', 'c']);
  });

  test('an evicted key loses its ready phase and is fetched again', () async {
    yt.autoFinish = true;
    prep.setQueue([for (final n in ['a', 'b', 'c', 'd']) _i(n)]);
    await _until(() => ['a', 'b', 'c', 'd'].every((n) => prep.phases.value['youtube:$n'] == StreamPhase.ready));
    final limit = cache.limitBytes;
    cache.limitBytes = 0;
    await cache.evict(); // d is not pinned
    expect(prep.phases.value.containsKey('youtube:d'), isFalse);
    expect(prep.phases.value['youtube:c'], StreamPhase.ready);
    cache.limitBytes = limit;
    prep.setQueue([for (final n in ['a', 'b', 'c', 'd']) _i(n)]);
    await _until(() => prep.phases.value['youtube:d'] == StreamPhase.ready);
    expect(yt.started.where((id) => id == 'd').length, 2);
  });

  test('a rate-limited prefetch completes rowId with an error', () async {
    final seen = Completer<Object>();
    enrich = (r, rowId) async {
      try {
        await rowId;
      } on Object catch (e) {
        seen.complete(e);
      }
    };
    make(cooldown: const Duration(minutes: 1));
    yt.autoFinish = true;
    yt.rateLimits['a'] = 1;
    prep.setQueue([_i('a')]);
    expect(await seen.future.timeout(const Duration(seconds: 2)), isA<YtException>());
  });

  for (final kind in ['429', '403']) {
    test('after a $kind no new prefetch starts before the cooldown', () async {
      make(cooldown: const Duration(minutes: 1));
      yt.autoFinish = true;
      (kind == '429' ? yt.rateLimits : yt.forbidden)['a'] = 1;
      prep.setQueue([_i('a')]);
      await _until(() => yt.started.isNotEmpty);
      await _quiet();
      prep.setQueue([_i('a'), _i('b')]); // pumps again
      await _quiet();
      expect(yt.started, ['a']);
    });
  }

  test('a rate-limited prefetch is forgotten, a requested ready() still runs', () async {
    make(cooldown: const Duration(minutes: 1));
    yt.autoFinish = true;
    yt.rateLimits['a'] = 1;
    prep.setQueue([_i('a')]);
    await _until(() => yt.started.isNotEmpty);
    await _quiet();
    expect(prep.phases.value.containsKey('youtube:a'), isFalse);
    await prep.ready('youtube:a', _r('a')); // runs during the pause
    expect(yt.started, ['a', 'a']);
  });

  test('ready() on a cached file pins it, refreshes its mtime and releases the pin', () async {
    yt.autoFinish = true;
    await prep.ready('youtube:a', _r('a'));
    final f = (await cache.fileFor('youtube:a'))!;
    await f.setLastModified(DateTime(2020));
    cache.limitBytes = 0;
    final slow = tracks = _SlowTracks(db);
    make();
    final r = prep.ready('youtube:a', _r('a'));
    await cache.evict(); // ready's pin is still set
    slow.gate.complete();
    expect((await r).existsSync(), isTrue);
    expect((await r).lastModifiedSync().year, greaterThan(2020));
    await cache.evict(); // pin released
    expect(await cache.fileFor('youtube:a'), isNull);
  });

  test('an attempt that hangs counts as failed: retry once, then error', () async {
    make(attemptTimeout: const Duration(milliseconds: 30));
    await expectLater(prep.ready('youtube:slow', _r('slow')), throwsA(isA<TimeoutException>()));
    expect(yt.started, ['slow', 'slow']);
  });

  test('a timed-out attempt is cancelled and the retry gets a fresh token and folder', () async {
    make(attemptTimeout: const Duration(milliseconds: 30));
    await expectLater(prep.ready('youtube:slow', _r('slow')), throwsA(isA<TimeoutException>()));
    final t = yt.tokens['slow']!, d = yt.dirs['slow']!;
    expect(t[0]!.isCancelled, isTrue);
    expect(t[1], isNot(same(t[0])));
    expect(d[1], isNot(d[0]));
  });

  test('a prefetch that leaves the queue is cancelled, a requested one keeps running', () async {
    prep.setQueue([_i('a'), _i('b')]);
    await _until(() => yt.started.length == 2);
    final b = prep.ready('youtube:b', _r('b')); // requested
    await _quiet(); // ready() marks its job after a cache lookup
    prep.setQueue([_i('c')]);
    expect(yt.tokens['a']!.single!.isCancelled, isTrue);
    expect(yt.tokens['b']!.single!.isCancelled, isFalse);
    yt.finish('b');
    await b;
  });

  test('a key re-queued while its dropped download winds down gets one new job', () async {
    prep.setQueue([_i('a'), _i('b')]);
    await _until(() => yt.started.length == 2);
    prep.setQueue([_i('b')]);
    prep.setQueue([_i('a'), _i('b')]);
    await _until(() => yt.started.where((id) => id == 'a').length == 2);
    await _quiet();
    expect(yt.started.where((id) => id == 'a').length, 2);
    expect(prep.phases.value['youtube:a'], StreamPhase.downloading);
    yt.finish('a');
    await _until(() => prep.phases.value['youtube:a'] == StreamPhase.ready);
  });

  test('a cache hit without a shadow row makes the row', () async {
    yt.autoFinish = true;
    await prep.ready('youtube:a', _r('a'));
    await db.delete(db.tracks).go();
    await prep.ready('youtube:a', _r('a'));
    expect(await tracks.streamRow('youtube:a'), isNotNull);
    expect(yt.started, ['a']);
  });

  test('a queue change drops stale jobs: the next one to start is the new head', () async {
    prep.setQueue([for (final n in ['a', 'b', 'c', 'd', 'e', 'f']) _i(n)]);
    await _until(() => yt.started.length == 2);
    prep.setQueue([_i('e'), _i('f')]); // a and b are cancelled and free their slots
    await _until(() => yt.started.length >= 3);
    expect(yt.started[2], 'e');
  });

  test('dispose mid-download: nothing else starts and nothing is thrown', () async {
    prep.setQueue([for (final n in ['a', 'b', 'c']) _i(n)]);
    await _until(() => yt.started.length == 2);
    final f = prep.ready('youtube:a', _r('a'));
    final failed = expectLater(f, throwsA(isA<StateError>()));
    prep.dispose();
    yt.finish('a');
    yt.finish('b');
    await failed;
    await _quiet();
    expect(yt.started, ['a', 'b']);
  });

  test('current and next 2 are pinned, and unpinned when they leave the queue', () async {
    yt.autoFinish = true;
    prep.setQueue([for (final n in ['a', 'b', 'c', 'd']) _i(n)]);
    await _until(() => ['a', 'b', 'c', 'd'].every((n) => prep.phases.value['youtube:$n'] == StreamPhase.ready));
    Future<bool> pinned(String k) async {
      // Evict at zero limit: only pinned files survive.
      cache.limitBytes = 0;
      await cache.evict();
      return await cache.fileFor(k) != null;
    }

    expect(await pinned('youtube:c'), isTrue);
    expect(await pinned('youtube:d'), isFalse);
    prep.setQueue([_i('d')]);
    expect(await pinned('youtube:c'), isFalse);
  });
}
