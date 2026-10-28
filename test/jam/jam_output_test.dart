import 'dart:async';

import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/jam/jam_clock.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_output.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';

void main() {
  syncTests();
  late FakeBackend backend;
  late JamOutput out;
  var now = 0;
  final ended = <int>[];
  final failed = <int>[];

  const a = JamItem(id: 1, ownerDeviceId: 'me', title: 'A', ext: 'mp3', ref: 'x');
  const b = JamItem(id: 2, ownerDeviceId: 'peer', title: 'B', ext: 'mp3');

  JamState st({
    List<JamItem> items = const [a, b],
    int cur = 0,
    bool playing = true,
    String output = 'me',
    int pos = 0,
    int at = 0,
  }) =>
      JamState(
        version: 1,
        items: items,
        currentIndex: cur,
        playing: playing,
        positionMs: pos,
        positionAt: at,
        hostDeviceId: 'host',
        outputDeviceId: output,
      );

  setUp(() {
    now = 0;
    ended.clear();
    failed.clear();
    backend = FakeBackend();
    out = JamOutput(
      deviceId: 'me',
      backend: backend,
      nowMs: () => now,
      resolve: (i) async => i.ownerDeviceId == 'me'
          ? JamSource.local('/music/${i.ref}.mp3')
          : JamSource.remote(
              Uri.parse('http://10.0.0.2:1/jam/s/file/${i.id}'), {'x-jam-token': 't'}),
    )
      ..onTrackEnded = ended.add
      ..onItemFailed = failed.add;
  });

  test('single output with a Jam clock seeks by the host clock, not the local one (R-94)',
      () async {
    var local = 100000; // this phone's clock; the host's is 2 s ahead
    final c = JamClock(
      probe: () async => (t0: local, hostMs: local + 2000, t1: local),
      localNowMs: () => local,
    );
    await c.sync();
    final o = JamOutput(
      deviceId: 'me',
      backend: backend,
      clock: c,
      syncInterval: const Duration(hours: 1),
      resolve: (i) async => const JamSource.local('/m.mp3'),
    );
    // Host started the item at its own time 102000 from 0 ms; 3 s later
    // (host time 105000) it must be at 3 s.
    await o.apply(st(at: 102000));
    local += 3000;
    await o.apply(st(at: 102000)); // same item, re-applied
    expect(backend.seeks.last, const Duration(milliseconds: 3000));
    await o.dispose();
  });

  test('single output re-checks the position when the Jam clock settles', () async {
    var local = 100000;
    var skew = 0; // clock not synced yet
    final c = JamClock(
      probe: () async => (t0: local, hostMs: local + skew, t1: local),
      localNowMs: () => local,
    );
    final o = JamOutput(
      deviceId: 'me',
      backend: backend,
      clock: c,
      syncInterval: const Duration(milliseconds: 50),
      resolve: (i) async => const JamSource.local('/m.mp3'),
    );
    await o.apply(st(at: 100000));
    local += 3000;
    // Host clock (offset 0): the player 300 ms late is left alone.
    backend.positionValue = const Duration(milliseconds: 2700);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(backend.seeks, isEmpty);
    backend.positionValue = Duration.zero;
    skew = 2000; // the host is 2 s ahead: the output is 2 s behind
    await c.sync();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(backend.seeks.single, const Duration(milliseconds: 5000));
    await o.dispose();
  });

  test('single output: one re-check per clock offset, none while the next item loads',
      () async {
    var local = 100000;
    var skew = 0;
    final gate = Completer<void>();
    final c = JamClock(
      probe: () async => (t0: local, hostMs: local + skew, t1: local),
      localNowMs: () => local,
    );
    final o = JamOutput(
      deviceId: 'me',
      backend: backend,
      clock: c,
      syncInterval: const Duration(milliseconds: 50),
      resolve: (i) async {
        if (i.id == 2) await gate.future;
        return const JamSource.local('/m.mp3');
      },
    );
    await o.apply(st(at: 100000));
    local += 3000;
    // New item still resolving: the old one must not be moved to its position.
    unawaited(o.apply(st(cur: 1, at: 100000)));
    backend.positionValue = Duration.zero;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(backend.seeks, isEmpty);
    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    backend.seeks.clear();
    skew = 2000;
    await c.sync();
    backend.positionValue = Duration.zero;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(backend.seeks, hasLength(1)); // drift persists, same offset: no 2nd seek
    skew = 3000;
    await c.sync();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(backend.seeks, hasLength(2));
    await o.dispose();
  });

  test('plays own item locally, remote item with the token header', () async {
    await out.apply(st());
    expect(backend.loaded, ['/music/x.mp3']);
    expect(backend.playing, true);
    await out.apply(st(cur: 1));
    expect(backend.loadedUris.single.headers['x-jam-token'], 't');
    expect(backend.loadedUris.single.uri.path, '/jam/s/file/2');
  });

  test('not the output: stays silent and stops when output moves away', () async {
    await out.apply(st(output: 'host'));
    expect(backend.loaded, isEmpty);
    await out.apply(st());
    expect(backend.playing, true);
    await out.apply(st(output: 'host'));
    expect(backend.playing, false);
    expect(out.loadedItemId, isNull);
  });

  test('pause follows state; same item is not reloaded', () async {
    await out.apply(st());
    await out.apply(st(playing: false));
    expect(backend.playing, false);
    await out.apply(st());
    expect(backend.loaded, hasLength(1));
  });

  test('drift tolerance: small drift ignored, big drift seeks', () async {
    final b2 = FakeBackend();
    final seeks = b2.seeks;
    final o = JamOutput(
        deviceId: 'me', backend: b2, nowMs: () => now,
        resolve: (i) async => const JamSource.local('/a.mp3'));
    await o.apply(st());
    b2.posC.add(const Duration(seconds: 10));
    await Future<void>.delayed(Duration.zero);
    now = 10500; // target 10.5s vs 10s: inside tolerance
    await o.apply(st());
    expect(seeks, isEmpty);
    now = 14000; // 4s away
    await o.apply(st());
    expect(seeks, [const Duration(seconds: 14)]);
  });

  test('reports natural end once, and failures', () async {
    await out.apply(st());
    backend.stateC.add(BackendState.completed);
    backend.stateC.add(BackendState.completed);
    await Future<void>.delayed(Duration.zero);
    expect(ended, [1]);

    backend.failing.add('http://10.0.0.2:1/jam/s/file/2');
    await out.apply(st(cur: 1));
    expect(failed, [2]);
  });
}

void syncTests() {
  group('synchronised output', () {
    late FakeBackend backend;
    late JamClock clock;
    late JamOutput out;
    var local = 0; // this device's clock
    const hostSkew = 5000; // the host clock is 5 s ahead
    final errors = <int>[];

    const item = JamItem(
        id: 1, ownerDeviceId: 'me', title: 'A', ext: 'mp3', ref: 'x', durationMs: 300000);

    JamState st({
      bool playing = true,
      int pos = 0,
      required int at,
      List<String> outputs = const ['me', 'peer'],
    }) =>
        JamState(
          version: 1,
          items: const [item],
          currentIndex: 0,
          playing: playing,
          positionMs: pos,
          positionAt: at,
          hostDeviceId: 'host',
          outputDeviceId: outputs.first,
          outputDeviceIds: outputs,
          participants: const [
            JamParticipant(id: 'host', name: 'H'),
            JamParticipant(id: 'me', name: 'M', host: '10.0.0.2', port: 1),
            JamParticipant(id: 'peer', name: 'P', host: '10.0.0.3', port: 1),
          ],
        );

    setUp(() async {
      local = 0;
      errors.clear();
      backend = FakeBackend();
      clock = JamClock(
        localNowMs: () => local,
        samples: 1,
        probe: () async => (t0: local, hostMs: local + hostSkew, t1: local),
      );
      await clock.sync();
      out = JamOutput(
        deviceId: 'me',
        backend: backend,
        clock: clock,
        syncInterval: const Duration(hours: 1),
        resolve: (i) async => const JamSource.local('/m.mp3'),
      )..onSyncError = errors.add;
    });

    tearDown(() => out.dispose());

    test('loads, waits for the instant, then plays from position', () async {
      // jam time now = 5000; start scheduled 1.5 s ahead
      await out.apply(st(at: 6500));
      expect(backend.loaded, ['/m.mp3']);
      expect(backend.playing, false);
      expect(backend.seeks, isEmpty);

      local = 1400; // jam 6400: still waiting
      await out.apply(st(at: 6500));
      expect(backend.playing, false);

      local = 1500; // jam 6500: go
      await out.apply(st(at: 6500));
      expect(backend.playing, true);
    });

    test('a late joiner jumps to where the others are', () async {
      local = 10000; // jam 15000, started at 6500 => 8.5 s in
      await out.apply(st(at: 6500));
      expect(backend.playing, true);
      expect(backend.seeks.last, const Duration(milliseconds: 8500));
    });

    test('drift: small is ignored, medium slows down, big seeks', () async {
      local = 10000;
      await out.apply(st(at: 6500)); // now playing at 8500
      backend.positionValue = const Duration(milliseconds: 8500);
      local = 11000; // expected 9500
      backend.positionValue = const Duration(milliseconds: 9515);
      await out.apply(st(at: 6500));
      expect(backend.speed, 1.0);
      backend.positionValue = const Duration(milliseconds: 9590); // 90 ahead
      await out.apply(st(at: 6500));
      expect(backend.speed, closeTo(0.9775, 1e-3));
      backend.positionValue = const Duration(milliseconds: 12000); // far
      await out.apply(st(at: 6500));
      expect(backend.seeks.last, const Duration(milliseconds: 9500));
      expect(backend.speed, 1.0);
      expect(errors, isNotEmpty);
    });

    test('latency setting runs the player ahead', () async {
      out.latencyMs = 200;
      local = 10000;
      await out.apply(st(at: 6500));
      expect(backend.seeks.last, const Duration(milliseconds: 8700));
    });

    test('leaving the output set stops playback and restores speed', () async {
      local = 10000;
      await out.apply(st(at: 6500));
      backend.positionValue = const Duration(milliseconds: 9000);
      await out.apply(st(at: 6500));
      await out.apply(st(at: 6500, outputs: const ['peer']));
      expect(backend.playing, false);
    });

    test('without a clock a multi-output Jam behaves like one output', () async {
      final plain = JamOutput(
        deviceId: 'me',
        backend: backend,
        syncInterval: const Duration(hours: 1),
        resolve: (i) async => const JamSource.local('/m.mp3'),
        nowMs: () => local + hostSkew,
      );
      await plain.apply(st(at: 0));
      expect(backend.playing, true);
      await plain.dispose();
    });
  });
}
