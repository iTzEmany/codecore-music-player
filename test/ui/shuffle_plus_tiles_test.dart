import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/shuffle_plus_providers.dart';
import 'package:codecore/ui/screens/settings/shuffle_plus_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets(
    'Shuffle+ settings: no switch for Shuffle+, a note, interval and Wi‑Fi tiles; the state is shown',
    (tester) async {
      final h = await Harness.create(tester, tracks: 2);
      await h.pump(
        tester,
        const Scaffold(body: SingleChildScrollView(child: ShufflePlusTiles())),
        extraOverrides: [
          shufflePlusBlockProvider.overrideWith(
            (ref) async => ShufflePlusBlock.metered,
          ),
        ],
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(ShufflePlusTiles)),
      );
      expect(find.text('Un suggerito ogni 4 brani'), findsOneWidget);
      expect(find.text('Spento: la casuale resta normale.'), findsOneWidget);

      expect(
        find.textContaining('Si attiva dal pulsante shuffle'),
        findsOneWidget,
      );
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget); // only «Solo su Wi‑Fi»
      c
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(shufflePlus: true));
      await tester.runAsync(() async {
        await c.read(playerControllerProvider).setShuffle(true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('In pausa: rete a consumo'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(c.read(settingsProvider).shufflePlusUnmeteredOnly, isFalse);
      await h.dispose(tester);
    },
  );
}
