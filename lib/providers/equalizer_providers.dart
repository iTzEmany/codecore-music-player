import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../core/platform.dart';
import '../data/settings/settings_store.dart';
import '../services/audio/equalizer.dart';
import '../services/audio/output_route.dart';
import 'player_providers.dart';
import 'settings_providers.dart';

/// What the sound is coming out of; each has its own curve.
enum OutputRoute { speaker, headphones }

class OutputRouteNotifier extends Notifier<OutputRoute> {
  @override
  OutputRoute build() => OutputRoute.speaker;

  void set(OutputRoute r) => state = r;
}

/// Set from the platform (Android: wired, Bluetooth or USB headphones).
final outputRouteProvider =
    NotifierProvider<OutputRouteNotifier, OutputRoute>(OutputRouteNotifier.new);

/// The main player's equalizer; null on platforms without one.
final equalizerProvider =
    Provider<Equalizer?>((ref) => ref.watch(audioHandlerProvider).equalizer);

/// Band layout, once the platform reports it (after the first track loads).
final equalizerBandsProvider = FutureProvider<EqBands?>(
  (ref) async => ref.watch(equalizerProvider)?.bands(),
);

/// The curve in use for [route].
EqProfile eqProfileFor(AppSettings s, OutputRoute route) =>
    route == OutputRoute.headphones ? s.eqHeadphones : s.eqSpeaker;

/// Gains for [profile] on [bands]: the preset interpolated, or the user's own.
List<double> gainsFor(EqProfile profile, EqBands bands) =>
    profile.preset == EqPreset.custom
        ? fitGains(profile.custom, bands.count, bands.minDb, bands.maxDb)
        : presetGains(profile.preset, bands.centerHz,
            minDb: bands.minDb, maxDb: bands.maxDb);

/// Keeps the equalizer in line with the settings and the output in use.
/// Watched once, from the app root.
final equalizerApplierProvider = Provider<void>((ref) {
  final eq = ref.watch(equalizerProvider);
  if (eq == null) return;
  var token = 0;

  Future<void> apply() async {
    final mine = ++token;
    final s = ref.read(settingsProvider);
    final route = ref.read(outputRouteProvider);
    try {
      // Waits for the first track on Android: the effect needs an audio session.
      final bands = await eq.bands();
      if (mine != token) return;
      await eq.setGains(gainsFor(eqProfileFor(s, route), bands));
      await eq.setEnabled(s.eqEnabled);
    } on Object catch (e, st) {
      AppLog.w('equalizer could not be applied', e, st);
    }
  }

  ref.listen(settingsProvider.select((s) => (s.eqEnabled, s.eqSpeaker, s.eqHeadphones)),
      (_, _) => unawaited(apply()));
  ref.listen(outputRouteProvider, (_, _) => unawaited(apply()));
  unawaited(apply());
});

/// Android only: follows the output (headphones or speaker) into
/// [outputRouteProvider]. Watched once, from the app root.
final outputRouteSyncProvider = Provider<void>((ref) {
  if (!isAndroid) return;
  final channel = watchOutputRoute((headphones) => ref
      .read(outputRouteProvider.notifier)
      .set(headphones ? OutputRoute.headphones : OutputRoute.speaker));
  ref.onDispose(() => channel.setMethodCallHandler(null));
});
