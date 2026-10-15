import 'dart:async';

/// One timestamp exchange: local time before sending, the host's clock as it
/// answered, local time on arrival (all epoch ms).
typedef JamTimeSample = ({int t0, int hostMs, int t1});

/// Asks the host for its clock. Returns null on failure.
typedef JamTimeProbe = Future<JamTimeSample?> Function();

/// Estimates the offset between this device and the Jam host (NTP style) and
/// answers "what time is it for the Jam". Differences are measured on a
/// monotonic stopwatch so system clock jumps do not move the estimate.
class JamClock {
  JamClock({
    required this.probe,
    int Function()? localNowMs,
    this.samples = 8,
    this.keepBest = 3,
    this.maxRttMs = 1500,
  }) : _local = localNowMs ?? _defaultLocal();

  final JamTimeProbe probe;
  final int samples, keepBest, maxRttMs;
  final int Function() _local;
  Timer? _timer;

  int _offsetMs = 0;
  int _bestRttMs = -1;
  bool _synced = false;

  /// host clock − local clock, in ms.
  int get offsetMs => _offsetMs;

  /// Round trip of the sample the offset is based on (an error bound is half
  /// of it). -1 before the first successful sync.
  int get rttMs => _bestRttMs;

  bool get synced => _synced;

  int localNowMs() => _local();

  /// Current time in the Jam's reference clock.
  int jamNowMs() => _local() + _offsetMs;

  static int Function() _defaultLocal() {
    final base = DateTime.now().millisecondsSinceEpoch;
    final sw = Stopwatch()..start();
    return () => base + sw.elapsedMilliseconds;
  }

  /// Takes up to [samples] exchanges and keeps the offset of the best ones
  /// (lowest RTT; the median of the [keepBest] fastest).
  Future<bool> sync() async {
    final good = <({int rtt, int offset})>[];
    for (var i = 0; i < samples; i++) {
      final s = await probe();
      if (s == null) continue;
      final rtt = s.t1 - s.t0;
      if (rtt < 0 || rtt > maxRttMs) continue;
      // The host stamped its answer about half way through the exchange.
      good.add((rtt: rtt, offset: s.hostMs - (s.t0 + rtt ~/ 2)));
    }
    if (good.isEmpty) return false;
    good.sort((a, b) => a.rtt.compareTo(b.rtt));
    // A round that was much slower than what we already know carries a
    // larger error: keep the old estimate (it still follows slow drift when
    // a good round comes in).
    if (_synced && good.first.rtt > _bestRttMs * 3 + 30) return false;
    final best = good.take(keepBest).toList()
      ..sort((a, b) => a.offset.compareTo(b.offset));
    _offsetMs = best[best.length ~/ 2].offset;
    _bestRttMs = good.first.rtt;
    _synced = true;
    return true;
  }

  /// Re-syncs every [every] until [stop].
  void start({Duration every = const Duration(seconds: 30)}) {
    _timer?.cancel();
    // A first refinement soon after the initial burst (Wi-Fi often settles).
    Timer(const Duration(seconds: 5), () {
      if (_timer != null) unawaited(sync());
    });
    _timer = Timer.periodic(every, (_) => unawaited(sync()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
