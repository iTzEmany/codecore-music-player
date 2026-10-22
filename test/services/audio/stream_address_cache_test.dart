import 'dart:async';

import 'package:codecore/services/audio/stream_address_cache.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:flutter_test/flutter_test.dart';

const r1 = YtResult(id: 'a', title: 't', channel: 'c', duration: null);
const r2 = YtResult(id: 'b', title: 't', channel: 'c', duration: null);

final t0 = DateTime.utc(2026, 1, 1, 12);

Uri addr(String id, DateTime expiry) => Uri.parse(
  'https://x.googlevideo.com/$id?expire=${expiry.millisecondsSinceEpoch ~/ 1000}',
);

void main() {
  late DateTime now;
  late int calls;

  setUp(() {
    now = t0;
    calls = 0;
  });

  StreamAddressCache makeFast(
          Future<StreamAddress> Function(YtResult, {required bool fast}) resolve,
          {FastClientGate? gate}) =>
      StreamAddressCache(
        (r, {required fast}) {
          calls++;
          return resolve(r, fast: fast);
        },
        gate: gate,
        now: () => now,
        wait: const Duration(milliseconds: 200),
      );

  StreamAddressCache make(Future<Uri> Function(YtResult) resolve) =>
      makeFast((r, {required fast}) async => StreamAddress(await resolve(r)));

  test('expiryOf reads expire in Unix seconds, null when missing', () {
    expect(
      expiryOf(addr('a', t0.add(const Duration(hours: 6)))),
      t0.add(const Duration(hours: 6)),
    );
    expect(expiryOf(Uri.parse('https://x/y?a=1')), isNull);
    expect(expiryOf(Uri.parse('https://x/y?expire=oops')), isNull);
  });

  test('reuses the address until the margin, then asks again', () async {
    final c = make((r) async => addr(r.id, t0.add(const Duration(hours: 6))));
    await c.address(r1);
    await c.address(r1);
    expect(calls, 1);
    now = t0.add(const Duration(hours: 5, minutes: 49));
    await c.address(r1);
    expect(calls, 1);
    now = t0.add(const Duration(hours: 5, minutes: 51));
    await c.address(r1);
    expect(calls, 2);
  });

  test('an address without expire is renewed every time', () async {
    final c = make((r) async => Uri.parse('https://x/${r.id}'));
    await c.address(r1);
    await c.address(r1);
    expect(calls, 2);
  });

  test('two concurrent calls make one request', () async {
    final done = Completer<Uri>();
    final c = make((_) => done.future);
    final a = c.address(r1);
    final b = c.address(r1);
    final u = addr('a', t0.add(const Duration(hours: 6)));
    done.complete(u);
    expect((await a).uri, u);
    expect((await b).uri, u);
    expect(calls, 1);
  });

  test('prefetch does not wait and address then reuses its request', () async {
    final done = Completer<Uri>();
    final c = make((_) => done.future);
    c.prefetch(r1);
    final a = c.address(r1);
    done.complete(addr('a', t0.add(const Duration(hours: 6))));
    await a;
    expect(calls, 1);
  });

  test('invalidate forces a new request', () async {
    final c = make((r) async => addr(r.id, t0.add(const Duration(hours: 6))));
    await c.address(r1);
    c.invalidate(r1);
    await c.address(r1);
    expect(calls, 2);
  });

  test(
    'a resolver error reaches every waiter, and a retry asks again',
    () async {
      final done = Completer<Uri>();
      final c = make((_) => done.future);
      final a = expectLater(c.address(r1), throwsA(isA<StateError>()));
      final b = expectLater(c.address(r1), throwsA(isA<StateError>()));
      done.completeError(StateError('boom'));
      await a;
      await b;
      expect(calls, 1);
      final c2 = make(
        (r) async => addr(r.id, t0.add(const Duration(hours: 6))),
      );
      await c2.address(r1);
    },
  );

  test('a failed prefetch is swallowed', () async {
    final c = make((_) async => throw StateError('boom'));
    c.prefetch(r1);
    await Future<void>.delayed(Duration.zero);
    await expectLater(c.address(r1), throwsA(isA<StateError>()));
    expect(calls, 2);
  });

  test('waiting longer than `wait` times out', () async {
    final c = make((_) => Completer<Uri>().future);
    await expectLater(c.address(r1), throwsA(isA<TimeoutException>()));
  });

  test('keeps at most 20 addresses', () async {
    final c = make((r) async => addr(r.id, t0.add(const Duration(hours: 6))));
    YtResult r(int i) =>
        YtResult(id: 'v$i', title: 't', channel: 'c', duration: null);
    for (var i = 0; i < 21; i++) {
      await c.address(r(i));
    }
    expect(calls, 21);
    await c.address(r(20));
    expect(calls, 21);
    await c.address(r(0)); // the oldest was dropped
    expect(calls, 22);
  });

  group('quick client', () {
    final far = t0.add(const Duration(hours: 6));
    late List<bool> asked;
    StreamAddressCache quick({FastClientGate? gate}) {
      asked = [];
      return makeFast((r, {required fast}) async {
        asked.add(fast);
        return StreamAddress(addr(r.id, far),
            headers: const {'User-Agent': 'vr'}, fast: fast);
      }, gate: gate);
    }

    test('carries the headers of the address', () async {
      final a = await quick().address(r1);
      expect(a.headers, {'User-Agent': 'vr'});
    });

    test('a refused quick address is asked again with the default clients',
        () async {
      final c = quick();
      await c.address(r1);
      c.invalidate(r1);
      final again = await c.address(r1);
      expect(asked, [true, false]);
      expect(again.fast, isFalse);
      // Another track still starts with the quick client.
      await c.address(r2);
      expect(asked.last, isTrue);
    });

    test('a refused default address does not count against the quick client',
        () async {
      final gate = FastClientGate();
      final c = quick(gate: gate);
      await c.address(r1);
      c.invalidate(r1); // quick: 1
      await c.address(r1);
      c.invalidate(r1); // default: not counted
      expect(gate.failures, 1);
      expect(gate.enabled, isTrue);
    });

    test('after two refusals the quick client is off for the session',
        () async {
      final c = quick();
      for (final r in [r1, r2]) {
        await c.address(r);
        c.invalidate(r);
      }
      expect(c.gate.enabled, isFalse);
      const r3 = YtResult(id: 'c', title: 't', channel: 'c', duration: null);
      await c.address(r3);
      expect(asked, [true, true, false]);
    });
  });
}
