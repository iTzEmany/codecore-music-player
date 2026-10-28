import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/player_providers.dart';

/// The one playback position the UI draws: the last known position advanced
/// by a clock, emitted every [interval] (10 per second). A periodic timer
/// rather than a Ticker, so it does not ask for a frame on every vsync. It
/// stands still while paused and, once [bindTickerMode] is called, while the
/// route is covered (`TickerMode` off), so nothing repaints off screen.
///
/// Own one per State, feed it with [update] (Jam: from JamState) or
/// [followPlayer] (local player), call [bindTickerMode] in
/// `didChangeDependencies`, and dispose it.
class SmoothPosition extends ChangeNotifier
    implements ValueListenable<Duration> {
  SmoothPosition({
    this.interval = const Duration(milliseconds: 100),
    @visibleForTesting Duration Function()? uptime,
  }) {
    if (uptime != null) {
      _uptime = uptime;
    } else {
      final sw = Stopwatch()..start();
      _uptime = () => sw.elapsed;
    }
  }

  final Duration interval;
  late final Duration Function() _uptime;

  Timer? _timer;
  ValueListenable<TickerModeData>? _mode;
  bool _enabled = true;

  Duration _value = Duration.zero;
  Duration _base = Duration.zero; // position known at [_baseAt]
  Duration _baseAt = Duration.zero; // uptime of [_base]
  Duration? _max;
  bool _playing = false;
  double _speed = 1;

  @override
  Duration get value => _value;

  /// New fact about the position. Safe to call on every upstream event.
  /// With a known [duration] the value never goes past it.
  void update(
    Duration position, {
    required bool playing,
    double speed = 1,
    Duration? duration,
  }) {
    _base = position;
    _baseAt = _uptime();
    _playing = playing;
    _speed = speed;
    _max = duration != null && duration > Duration.zero ? duration : null;
    _emit();
    _syncTimer();
  }

  /// Follows the local player (position, duration, play state) until [ref]'s
  /// owner is disposed. Call once, in `initState`.
  void followPlayer(WidgetRef ref) {
    void push() => update(
      ref.read(positionProvider).value ?? Duration.zero,
      playing: ref.read(isPlayingProvider).value ?? false,
      duration: ref.read(durationProvider).value,
    );
    ref.listenManual(positionProvider, (_, _) => push());
    ref.listenManual(isPlayingProvider, (_, _) => push());
    ref.listenManual(durationProvider, (_, _) => push());
    push();
  }

  /// Silences the updates while [context]'s route is covered. Call in
  /// `didChangeDependencies`.
  void bindTickerMode(BuildContext context) {
    final mode = TickerMode.getValuesNotifier(context);
    if (mode != _mode) {
      _mode?.removeListener(_onMode);
      (_mode = mode).addListener(_onMode);
    }
    _onMode();
  }

  void _onMode() {
    final on = _mode!.value.enabled;
    if (on == _enabled) return;
    _enabled = on;
    if (on) _emit(); // catch up with the time that passed
    _syncTimer();
  }

  void _syncTimer() {
    final run = _playing && _enabled;
    if (run && _timer == null) {
      _timer = Timer.periodic(interval, (_) => _emit());
    } else if (!run) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _emit() {
    var v = _playing ? _base + (_uptime() - _baseAt) * _speed : _base;
    if (_max != null && v > _max!) v = _max!;
    _value = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mode?.removeListener(_onMode);
    super.dispose();
  }
}
