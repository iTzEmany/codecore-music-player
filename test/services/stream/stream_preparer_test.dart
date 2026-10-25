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
class _Yt implements YoutubeService {
  final started = <String>[];
  final failuresLeft = <String, int>{};
  final rateLimits = <String, int>{};
  final _gates = <String, Completer<void>>{};
  var open = 0, maxOpen = 0;
  var autoFinish = false;

  void finish(String id) => _gates[id]!.complete();

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
      {CancelToken? cancel, DownloadOptions options = const DownloadOptions()}) async* {
    started.add(r.id);
    maxOpen = ++open > maxOpen ? open : maxOpen;
    try {
      final gate = _gates[r.id] = Completer<void>();
      if (autoFinish) gate.complete();
      await gate.future;
      if ((rateLimits[r.id] ?? 0) > 0) {
        rateLimits[r.id] = rateLimits[r.id]! - 1;
        throw const YtException(YtErrorKind.rateLimited, '429');
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
    prep.setQueue([for (final n in ['a', 'b', 'c', 'd']) _i(n)]);
    await _until(() => yt.started.length == 2);
    // The user skipped to d, then back to c: both asked, d first.
    final d = prep.ready('youtube:d', _r('d'));
    final c = prep.ready('youtube:c', _r('c'));
    yt.finish('a');
    await _until(() => yt.started.length == 3);
    expect(yt.started[2], 'c');
    yt.finish('b');
    await _until(() => yt.started.length == 4);
    yt.finish('c');
    yt.finish('d');
    await Future.wait([c, d]);
  });

  test('an attempt that hangs counts as failed: retry once, then error', () async {
    make(attemptTimeout: const Duration(milliseconds: 30));
    await expectLater(prep.ready('youtube:slow', _r('slow')), throwsA(isA<TimeoutException>()));
    expect(yt.started, ['slow', 'slow']);
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
    prep.setQueue([_i('e'), _i('f')]);
    yt.finish('a');
    await _until(() => yt.started.length == 3);
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
