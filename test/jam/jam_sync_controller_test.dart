import 'package:codecore/services/jam/jam_sync.dart';
import 'package:flutter_test/flutter_test.dart';

JamSyncAction decide({
  bool playing = true,
  int positionMs = 0,
  int positionAt = 1000,
  required int now,
  required int measured,
  bool backendPlaying = true,
  double speed = 1.0,
  int latency = 0,
}) =>
    const JamSyncController().decide(
      playing: playing,
      positionMs: positionMs,
      positionAtMs: positionAt,
      jamNowMs: now,
      measuredMs: measured,
      backendPlaying: backendPlaying,
      speed: speed,
      latencyMs: latency,
    );

void main() {
  group('start', () {
    test('waits in position until the scheduled instant', () {
      final a = decide(now: 400, measured: 0, backendPlaying: false);
      expect(a.playInMs, 600);
      expect(a.play, isNull);
      expect(a.seekToMs, isNull);
    });

    test('latency makes the start earlier', () {
      final a = decide(now: 400, measured: 0, backendPlaying: false, latency: 200);
      expect(a.playInMs, 400);
    });

    test('a player that is not in position is moved while waiting', () {
      final a = decide(now: 400, measured: 5000, backendPlaying: false);
      expect(a.seekToMs, 0);
    });

    test('a player already running before the start is stopped', () {
      final a = decide(now: 400, measured: 90, backendPlaying: true);
      expect(a.play, false);
      expect(a.seekToMs, 0);
    });

    test('at the instant: play at the expected position', () {
      final a = decide(now: 1000, measured: 0, backendPlaying: false);
      expect(a.play, true);
      expect(a.seekToMs, 0);
    });

    test('joining late: play from where the others are', () {
      final a = decide(
          positionMs: 30000, positionAt: 1000, now: 9000, measured: 0,
          backendPlaying: false);
      expect(a.play, true);
      expect(a.seekToMs, 38000);
    });
  });

  group('drift', () {
    test('small error is left alone', () {
      // expected 5000, measured 5020
      final a = decide(now: 6000, measured: 5020);
      expect(a.isNoop, true);
    });

    test('medium error is absorbed with speed', () {
      final ahead = decide(now: 6000, measured: 5100);
      expect(ahead.speed, closeTo(0.98, 1e-9));
      final behind = decide(now: 6000, measured: 4900);
      expect(behind.speed, closeTo(1.02, 1e-9));
      // already correcting: no repeated command
      expect(decide(now: 6000, measured: 5100, speed: 0.98).isNoop, true);
    });

    test('large error is a seek', () {
      final a = decide(now: 6000, measured: 7000, speed: 0.98);
      expect(a.seekToMs, 5000);
      expect(a.speed, 1.0);
    });

    test('normal speed resumes once close again', () {
      expect(decide(now: 6000, measured: 5008, speed: 0.98).speed, 1.0);
      // between reset and ignore thresholds the speed is kept
      expect(decide(now: 6000, measured: 5020, speed: 0.98).isNoop, true);
    });

    test('own latency shifts the target', () {
      // a device that needs to run 120 ms ahead is on target at 5120...
      expect(decide(now: 6000, measured: 5120, latency: 120).isNoop, true);
      // ...and is 'behind' at 5000, so it speeds up a little
      expect(decide(now: 6000, measured: 5000, latency: 120).speed, 1.02);
      // a big latency gap is a seek
      expect(decide(now: 6000, measured: 5000, latency: 400).seekToMs, 5400);
    });
  });

  group('not playing', () {
    test('pauses and re-positions', () {
      final a = decide(
          playing: false, positionMs: 8000, now: 9000, measured: 8700);
      expect(a.play, false);
      expect(a.seekToMs, 8000);
    });

    test('paused and in position: nothing to do', () {
      final a = decide(
          playing: false, positionMs: 8000, now: 9000, measured: 8050,
          backendPlaying: false);
      expect(a.isNoop, true);
    });
  });

  test('converges: a drifting player is held within tolerance', () {
    // 3 simulated devices whose players run at 0.995 / 1.0 / 1.004 speed.
    const rates = [0.995, 1.0, 1.004];
    const ctl = JamSyncController();
    final pos = [0.0, 0.0, 0.0];
    final speed = [1.0, 1.0, 1.0];
    var now = 1000;
    var worst = 0;
    for (var tick = 0; tick < 600; tick++) {
      // each tick is 500 ms
      now += 500;
      for (var i = 0; i < 3; i++) {
        pos[i] += 500 * rates[i] * speed[i];
        final a = ctl.decide(
          playing: true,
          positionMs: 0,
          positionAtMs: 1000,
          jamNowMs: now,
          measuredMs: pos[i].round(),
          backendPlaying: true,
          speed: speed[i],
        );
        if (a.seekToMs != null) pos[i] = a.seekToMs!.toDouble();
        if (a.speed != null) speed[i] = a.speed!;
        if (tick > 20) {
          final err = (pos[i] - (now - 1000)).abs().round();
          if (err > worst) worst = err;
        }
      }
    }
    expect(worst, lessThan(80));
  });
}
