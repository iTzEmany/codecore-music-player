import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_providers.dart';

class SleepTimerState {
  const SleepTimerState({this.endsAt, this.atTrackEnd = false});

  final DateTime? endsAt;
  final bool atTrackEnd;

  bool get active => endsAt != null || atTrackEnd;
}

/// Pauses playback after N minutes (with a short fade-out) or at the end of
/// the current track.
class SleepTimerNotifier extends Notifier<SleepTimerState> {
  static const fadeDuration = Duration(seconds: 5);
  static const _fadeSteps = 25;

  Timer? _timer;
  Timer? _fade;

  @override
  SleepTimerState build() {
    ref.onDispose(_cancelTimers);
    // «End of track» is over once the handler has stopped at it.
    final sub = ref
        .read(audioHandlerProvider)
        .pausedAtTrackEnd
        .listen((_) {
      if (state.atTrackEnd) state = const SleepTimerState();
    });
    ref.onDispose(sub.cancel);
    return const SleepTimerState();
  }

  void _cancelTimers() {
    _timer?.cancel();
    _fade?.cancel();
    _timer = null;
    _fade = null;
  }

  void startMinutes(int minutes) {
    cancel();
    final total = Duration(minutes: minutes);
    state = SleepTimerState(endsAt: DateTime.now().add(total));
    _timer = Timer(
      total > fadeDuration ? total - fadeDuration : Duration.zero,
      _startFade,
    );
  }

  void startAtTrackEnd() {
    cancel();
    ref.read(audioHandlerProvider).pauseAtTrackEnd = true;
    state = const SleepTimerState(atTrackEnd: true);
  }

  void cancel() {
    _cancelTimers();
    final h = ref.read(audioHandlerProvider);
    h.pauseAtTrackEnd = false;
    state = const SleepTimerState();
  }

  void _startFade() {
    final h = ref.read(audioHandlerProvider);
    final original = ref.read(volumeProvider);
    var step = 0;
    final interval = Duration(
      milliseconds: fadeDuration.inMilliseconds ~/ _fadeSteps,
    );
    _fade = Timer.periodic(interval, (t) async {
      step++;
      if (step < _fadeSteps) {
        await h.setVolume(original * (1 - step / _fadeSteps));
        return;
      }
      t.cancel();
      await h.pause();
      await h.setVolume(original);
      state = const SleepTimerState();
    });
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(
      SleepTimerNotifier.new,
    );
