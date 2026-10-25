import 'package:codecore/core/network_kind.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/shuffle_plus_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final store = await SettingsStore.open();
  final c = ProviderContainer(overrides: [
    settingsStoreProvider.overrideWithValue(store),
    ...overrides,
  ]);
  addTearDown(c.dispose);
  return c;
}

NetworkProbe _probe(Map<String, Object?> answer) {
  const channel = MethodChannel('codecore/net-test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => answer);
  addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  return NetworkProbe(channel: channel, android: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the engine config follows the settings, off and Wi‑Fi only by default', () async {
    final c = await _container();
    final cfg = c.read(shufflePlusConfigProvider);
    expect((cfg.enabled, cfg.every, cfg.unmeteredOnly), (false, 4, true));

    c.read(settingsProvider.notifier).update(
        (s) => s.copyWith(shufflePlus: true, shufflePlusEvery: 6, shufflePlusUnmeteredOnly: false));
    final now = c.read(shufflePlusConfigProvider);
    expect((now.enabled, now.every, now.unmeteredOnly), (true, 6, false));
  });

  test('on mobile data the metered answer is true, on Wi‑Fi false, with no network true', () async {
    Future<bool> asked(Map<String, Object?> answer) async {
      final c = await _container(overrides: [
        networkProbeProvider.overrideWithValue(_probe(answer)),
      ]);
      return c.read(shufflePlusMeteredProvider)();
    }

    expect(await asked({'metered': true, 'online': true}), isTrue);
    expect(await asked({'metered': false, 'online': true}), isFalse);
    expect(await asked({'metered': false, 'online': false}), isTrue);
  });

  test('without the Android channel the network is never metered', () async {
    final c = await _container();
    expect(await c.read(shufflePlusMeteredProvider)(), isFalse);
  });

  test('the reasons Shuffle+ is idle are reported in order', () {
    ShufflePlusBlock? of({
      bool jam = false,
      bool tool = true,
      bool metered = false,
      bool stopped = false,
    }) =>
        shufflePlusBlock(
            jam: jam,
            toolAvailable: tool,
            metered: metered,
            unmeteredOnly: true,
            stopped: stopped);
    expect(of(), isNull);
    expect(of(jam: true), ShufflePlusBlock.jam);
    expect(of(tool: false), ShufflePlusBlock.noTool);
    expect(of(metered: true), ShufflePlusBlock.metered);
    expect(of(stopped: true), ShufflePlusBlock.stopped);
  });
}
