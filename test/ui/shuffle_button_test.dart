import 'package:audio_service/audio_service.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/shuffle_plus_providers.dart';
import 'package:codecore/ui/widgets/play_buttons.dart';
import 'package:codecore/ui/widgets/shuffle_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('shuffle icon turns amethyst while shuffle is on',
      (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, Scaffold(body: ShuffleButton(onPressed: () {})));
    final cc = CcColors.notte;
    Color iconColor() =>
        tester.widget<Icon>(find.byIcon(Icons.shuffle_rounded)).color!;
    expect(iconColor(), cc.textMuted);

    await tester.runAsync(
        () => h.handler.setShuffleMode(AudioServiceShuffleMode.all));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(iconColor(), cc.accent);
    await h.dispose(tester);
  });

  testWidgets('the shuffle button goes off → shuffle → Shuffle+ → off and drives the engine config',
      (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const Scaffold(body: ShuffleModeButton()));
    final c = ProviderScope.containerOf(tester.element(find.byType(ShuffleModeButton)));
    c.read(shufflePlusConfigProvider);

    Future<void> tap() async {
      await tester.runAsync(() async {
        await tester.tap(find.byType(IconButton));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    ShuffleMode mode() => c.read(shuffleModeProvider);
    expect(mode(), ShuffleMode.off);
    expect(find.byKey(const ValueKey('shuffle-plus-badge')), findsNothing);

    await tap();
    expect(mode(), ShuffleMode.shuffle);
    expect(h.handler.shuffleEnabled, isTrue);
    expect(c.read(shufflePlusConfigProvider).enabled, isFalse);

    await tap();
    expect(mode(), ShuffleMode.plus);
    expect(c.read(shufflePlusConfigProvider).enabled, isTrue);
    expect(find.byKey(const ValueKey('shuffle-plus-badge')), findsOneWidget);
    expect(c.read(settingsProvider).shufflePlus, isTrue);

    await tap();
    expect(mode(), ShuffleMode.off);
    expect(h.handler.shuffleEnabled, isFalse);
    expect(c.read(shufflePlusConfigProvider).enabled, isFalse);
    await h.dispose(tester);
  });

  testWidgets('turning shuffle off from outside also drops the «+»', (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const Scaffold(body: ShuffleModeButton()));
    final c = ProviderScope.containerOf(tester.element(find.byType(ShuffleModeButton)));
    c.read(shufflePlusConfigProvider);
    await tester.runAsync(() async {
      await h.handler.setShuffleMode(AudioServiceShuffleMode.all);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 100));
    c.read(settingsProvider.notifier).update((s) => s.copyWith(shufflePlus: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.read(shuffleModeProvider), ShuffleMode.plus);

    await tester.runAsync(() async {
      await h.handler.setShuffleMode(AudioServiceShuffleMode.none);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.read(settingsProvider).shufflePlus, isFalse);
    await h.dispose(tester);
  });
}
