import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/shuffle_plus_providers.dart';
import 'package:codecore/ui/screens/settings/shuffle_plus_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('Shuffle+ settings: off at first; the switch turns shuffle and Shuffle+ on; the state is shown',
      (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(
      tester,
      const Scaffold(body: SingleChildScrollView(child: ShufflePlusTiles())),
      extraOverrides: [
        shufflePlusBlockProvider.overrideWith((ref) async => ShufflePlusBlock.metered),
      ],
    );
    final c = ProviderScope.containerOf(tester.element(find.byType(ShufflePlusTiles)));
    expect(find.text('Un suggerito ogni 4 brani'), findsOneWidget);
    expect(find.text('Spento: la casuale resta normale.'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byType(Switch).first);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.read(settingsProvider).shufflePlus, isTrue);
    expect(h.handler.shuffleEnabled, isTrue);
    expect(find.text('In pausa: rete a consumo'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    expect(c.read(settingsProvider).shufflePlusUnmeteredOnly, isFalse);
    await h.dispose(tester);
  });
}
