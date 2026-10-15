import 'dart:convert';

import 'package:codecore/services/jam/jam_clock.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:shelf/shelf.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake link: the host clock runs [skew] ms ahead of the local one and each
/// leg takes the given delays.
JamTimeProbe link({
  required int Function() local,
  required void Function(int) advance,
  required int skew,
  required List<(int, int)> legs, // (outbound, inbound) per exchange
}) {
  var i = 0;
  return () async {
    final (out, back) = legs[i++ % legs.length];
    final t0 = local();
    advance(out);
    final host = local() + skew;
    advance(back);
    return (t0: t0, hostMs: host, t1: local());
  };
}

void main() {
  test('symmetric delay: the offset is exact', () async {
    var now = 1000000;
    final c = JamClock(
      localNowMs: () => now,
      probe: link(
          local: () => now,
          advance: (d) => now += d,
          skew: 5000,
          legs: const [(20, 20)]),
    );
    expect(await c.sync(), true);
    expect(c.offsetMs, 5000);
    expect(c.jamNowMs(), now + 5000);
    expect(c.rttMs, 40);
  });

  test('asymmetric delay stays within half the RTT', () async {
    var now = 0;
    final c = JamClock(
      localNowMs: () => now,
      probe: link(
          local: () => now,
          advance: (d) => now += d,
          skew: -2500,
          legs: const [(10, 50)]),
    );
    await c.sync();
    expect((c.offsetMs - -2500).abs(), lessThanOrEqualTo(c.rttMs ~/ 2));
  });

  test('slow and failed samples are ignored in favour of the fastest', () async {
    var now = 0;
    final legs = [(400, 400), (15, 15), (900, 20), (16, 14), (2000, 2000)];
    var i = 0;
    final c = JamClock(
      localNowMs: () => now,
      probe: () async {
        if (i == 6) {
          i++;
          return null; // a lost packet
        }
        final (o, b) = legs[i++ % legs.length];
        final t0 = now;
        now += o;
        final host = now + 777;
        now += b;
        return (t0: t0, hostMs: host, t1: now);
      },
      samples: 8,
    );
    await c.sync();
    expect((c.offsetMs - 777).abs(), lessThanOrEqualTo(5));
    expect(c.rttMs, lessThanOrEqualTo(30));
  });

  test('no answer: not synced, offset untouched', () async {
    final c = JamClock(probe: () async => null);
    expect(await c.sync(), false);
    expect(c.synced, false);
    expect(c.offsetMs, 0);
  });

  test('re-sync follows a drifting host clock', () async {
    var now = 0;
    var skew = 100;
    final c = JamClock(
      localNowMs: () => now,
      samples: 3,
      probe: () async {
        final t0 = now;
        now += 5;
        final host = now + skew;
        now += 5;
        return (t0: t0, hostMs: host, t1: now);
      },
    );
    await c.sync();
    expect(c.offsetMs, 100);
    skew = 130;
    await c.sync();
    expect(c.offsetMs, 130);
  });

  test('a much slower round does not replace a good estimate', () async {
    var now = 0;
    var delay = 5;
    var skew = 300;
    final c = JamClock(
      localNowMs: () => now,
      samples: 3,
      probe: () async {
        final t0 = now;
        now += delay;
        final host = now + skew;
        now += delay;
        return (t0: t0, hostMs: host, t1: now);
      },
    );
    await c.sync();
    expect(c.offsetMs, 300);
    delay = 400; // congestion: RTT 800 ms
    skew = 999;
    expect(await c.sync(), false);
    expect(c.offsetMs, 300);
  });

  test('/time answers members with the host clock and refuses others', () async {
    final now = DateTime.fromMillisecondsSinceEpoch(1234567);
    final h = JamHost(deviceId: 'h', deviceName: 'H', now: () => now);
    final a = h.addMember(id: 'a', name: 'A', host: '10.0.0.2', port: 1)!;
    final handler = h.buildRouter().call;
    Future<Response> get(Map<String, String> hd) => Future.sync(() =>
        handler(Request('GET', Uri.parse('http://x/${a.sid}/time'), headers: hd)));
    expect((await get({})).statusCode, 401);
    final ok = await get({jamTokenHeader: a.token});
    expect(jsonDecode(await ok.readAsString()), {'t': 1234567});
  });
}
