import 'dart:math';

import 'package:codecore/services/jam/jam_clock.dart';
import 'package:codecore/services/jam/jam_sync.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates N outputs with skewed clocks, jittery links and players that run
/// slightly fast or slow, all following one shared position.
class SimDevice {
  SimDevice(this.skewMs, this.rate, this.rng, this.jitterMs, this.latencyMs);

  /// This device's wall clock = true time + skew.
  final int skewMs;
  final double rate; // player speed error
  final Random rng;
  final int jitterMs;
  final int latencyMs;

  late JamClock clock;
  double posMs = 0;
  double speed = 1.0;
  bool playing = false;

  /// Speed commands take a tick to reach the audio path.
  double? pendingSpeed;

  int local(int trueMs) => trueMs + skewMs;
}

void main() {
  // One behaviour, five random set-ups (skews, speed errors, jitter).
  test('four outputs stay together', () async {
    for (final seed in [1, 2, 3, 4, 5]) {
      final rng = Random(seed);
      const hostSkew = 987654; // the host's clock is far from everyone's
      var trueNow = 5000000;

      final devs = [
        for (var i = 0; i < 4; i++)
          SimDevice(rng.nextInt(2000000) - 1000000, 1 + (rng.nextDouble() - 0.5) * 0.01,
              rng, 25, i == 3 ? 120 : 0)
      ];
      for (final d in devs) {
        d.clock = JamClock(
          localNowMs: () => d.local(trueNow),
          probe: () async {
            final t0 = d.local(trueNow);
            final out = 4 + d.rng.nextInt(d.jitterMs);
            trueNow += out;
            final host = trueNow + hostSkew;
            final back = 4 + d.rng.nextInt(d.jitterMs);
            trueNow += back;
            return (t0: t0, hostMs: host, t1: d.local(trueNow));
          },
        );
        await d.clock.sync();
      }

      // the shared state: start 1.5 s from "now" in the host's clock
      final positionAt = trueNow + hostSkew + 1500;
      const ctl = JamSyncController();
      var worst = 0;
      for (var step = 0; step < 1200; step++) {
        // 500 ms ticks = 10 minutes
        trueNow += 500;
        for (final d in devs) {
          if (d.pendingSpeed != null) {
            d.speed = d.pendingSpeed!;
            d.pendingSpeed = null;
          }
          if (d.playing) d.posMs += 500 * d.rate * d.speed;
          final a = ctl.decide(
            playing: true,
            positionMs: 0,
            positionAtMs: positionAt,
            jamNowMs: d.clock.jamNowMs(),
            measuredMs: d.posMs.round() + d.rng.nextInt(21) - 10,
            backendPlaying: d.playing,
            speed: d.speed,
            latencyMs: d.latencyMs,
          );
          if (a.seekToMs != null) d.posMs = a.seekToMs!.toDouble();
          if (a.speed != null) d.pendingSpeed = a.speed;
          if (a.play != null) d.playing = a.play!;
          if (a.playInMs != null && a.playInMs! <= 500) d.playing = true;
        }
        // re-sync every 30 s, like the app
        if (step % 60 == 59) {
          for (final d in devs) {
            await d.clock.sync();
          }
        }
        if (step > 40) {
          // what is heard: player position minus the device's own latency
          final heard = [for (final d in devs) d.posMs - d.latencyMs];
          final spread = (heard.reduce(max) - heard.reduce(min)).round();
          if (spread > worst) worst = spread;
        }
      }
      expect(worst, lessThan(80), reason: 'seed $seed: worst spread $worst ms');
    }
  });
}
