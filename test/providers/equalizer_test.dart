import 'dart:async';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/equalizer_providers.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/equalizer.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_backend.dart';

class FakeEq implements Equalizer {
  FakeEq({Completer<EqBands>? ready})
      : _ready = ready ?? (Completer<EqBands>()..complete(_five));
  static const _five = EqBands(
      centerHz: [60, 230, 910, 3600, 14000], minDb: -15, maxDb: 15);
  final Completer<EqBands> _ready;
  final enabledCalls = <bool>[];
  final gainCalls = <List<double>>[];

  @override
  Future<EqBands> bands() => _ready.future;
  @override
  Future<void> setEnabled(bool enabled) async => enabledCalls.add(enabled);
  @override
  Future<void> setGains(List<double> gainsDb) async => gainCalls.add(gainsDb);
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  late AppDatabase db;
  late FakeBackend backend;
  late FakeEq eq;
  late ProviderContainer c;

  Future<ProviderContainer> make({FakeEq? withEq, bool noEq = false}) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    backend = FakeBackend();
    eq = withEq ?? FakeEq();
    if (!noEq) backend.equalizer = eq;
    final handler = CodecoreAudioHandler(backend, PlayQueue(), TrackRepository(db),
        onError: (_) {});
    final container = ProviderContainer(overrides: [
      settingsStoreProvider.overrideWithValue(store),
      audioHandlerProvider.overrideWithValue(handler),
    ]);
    addTearDown(() async {
      container.dispose();
      await handler.dispose();
    });
    container.listen(equalizerApplierProvider, (_, _) {});
    return container;
  }

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('the settings reach the equalizer: off and flat at first', () async {
    c = await make();
    await settle();
    expect(eq.enabledCalls.last, isFalse);
    expect(eq.gainCalls.last, everyElement(0));
  });

  test('turning it on with a preset sends that preset on the real bands', () async {
    c = await make();
    await settle();
    c.read(settingsProvider.notifier).update((s) => s.copyWith(
        eqEnabled: true,
        eqSpeaker: const EqProfile(preset: EqPreset.bass)));
    await settle();
    expect(eq.enabledCalls.last, isTrue);
    expect(eq.gainCalls.last, hasLength(5));
    expect(eq.gainCalls.last.first, greaterThan(4));
    expect(eq.gainCalls.last.last, closeTo(0, 1e-9));
  });

  test('a custom curve is fitted to the device and clamped to its limits',
      () async {
    c = await make();
    await settle();
    c.read(settingsProvider.notifier).update((s) => s.copyWith(
        eqEnabled: true,
        eqSpeaker: const EqProfile(preset: EqPreset.custom, custom: [3, 99, -99])));
    await settle();
    expect(eq.gainCalls.last, [3, 15, -15, 0, 0]);
  });

  test('each output has its own curve and switching applies the right one',
      () async {
    c = await make();
    await settle();
    c.read(settingsProvider.notifier).update((s) => s.copyWith(
        eqEnabled: true,
        eqSpeaker: const EqProfile(preset: EqPreset.flat),
        eqHeadphones: const EqProfile(preset: EqPreset.treble)));
    await settle();
    expect(eq.gainCalls.last, everyElement(0), reason: 'speaker is the default');
    c.read(outputRouteProvider.notifier).set(OutputRoute.headphones);
    await settle();
    expect(eq.gainCalls.last.last, greaterThan(4), reason: 'headphones: treble');
    c.read(outputRouteProvider.notifier).set(OutputRoute.speaker);
    await settle();
    expect(eq.gainCalls.last, everyElement(0));
  });

  test('before the platform reports its bands nothing is applied, then it is',
      () async {
    final ready = Completer<EqBands>();
    c = await make(withEq: FakeEq(ready: ready));
    c.read(settingsProvider.notifier).update((s) => s.copyWith(
        eqEnabled: true, eqSpeaker: const EqProfile(preset: EqPreset.bass)));
    await settle();
    expect(eq.gainCalls, isEmpty);
    ready.complete(FakeEq._five);
    await settle();
    expect(eq.gainCalls.last.first, greaterThan(4));
    expect(eq.enabledCalls.last, isTrue);
  });

  test('a backend without an equalizer is simply left alone', () async {
    c = await make(noEq: true);
    c.read(settingsProvider.notifier).update((s) => s.copyWith(eqEnabled: true));
    await settle();
    expect(c.read(equalizerProvider), isNull);
    expect(eq.gainCalls, isEmpty);
  });

  test('settings keep the profiles and survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    expect(store.readSettings().eqEnabled, isFalse);
    expect(store.readSettings().eqSpeaker.preset, EqPreset.flat);
    await store.writeSettings(const AppSettings(
      eqEnabled: true,
      eqSpeaker: EqProfile(preset: EqPreset.custom, custom: [1.5, -2, 0, 3, 4]),
      eqHeadphones: EqProfile(preset: EqPreset.bass),
    ));
    final back = store.readSettings();
    expect(back.eqEnabled, isTrue);
    expect(back.eqSpeaker.preset, EqPreset.custom);
    expect(back.eqSpeaker.custom, [1.5, -2, 0, 3, 4]);
    expect(back.eqHeadphones.preset, EqPreset.bass);
    expect(back.eqHeadphones.custom, isEmpty);
  });
}
