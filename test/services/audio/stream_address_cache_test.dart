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

  StreamAddressCache make(Future<Uri> Function(YtResult) resolve) =>
      StreamAddressCache(
        (r) {
          calls++;
          return resolve(r);
        },
        now: () => now,
        wait: const Duration(milliseconds: 200),
      );

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
    expect(await a, u);
    expect(await b, u);
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
}
