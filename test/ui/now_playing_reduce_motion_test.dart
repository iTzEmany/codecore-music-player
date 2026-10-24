import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_cards.dart';
import 'package:drift/drift.dart' show Value;
import 'package:codecore/ui/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/spin_support.dart';

void main() {
  testWidgets('option off (default): the cover does not turn', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: spinOverrides(spinCover: false),
      child: const MaterialApp(
        home: Scaffold(body: SpinWhilePlaying(trackKey: 'a', child: SizedBox(width: 10, height: 10))),
      ),
    ));
    await tester.pump(const Duration(seconds: 5));
    expect(find.descendant(of: find.byType(SpinWhilePlaying), matching: find.byType(RotationTransition)), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final off in [true, false]) {
    testWidgets('curiosity AnimatedSize duration is ${off ? 'zero' : 'not zero'} (disableAnimations: $off)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester, tracks: 1);
      await tester.runAsync(() => h.db.update(h.db.tracks).write(const TracksCompanion(
            curiosities: Value('Testo\nhttps://it.wikipedia.org/wiki/Song'),
          )));
      final track = (await tester.runAsync(() => h.db.select(h.db.tracks).getSingle()))!;
      await h.pump(
        tester,
        Builder(
          builder: (c) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: off),
            child: Scaffold(body: SingleChildScrollView(child: InfoCard(track: track))),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
      await tester.pump(const Duration(milliseconds: 300));
      final size = tester.widget<AnimatedSize>(find.byType(AnimatedSize).first);
      expect(size.duration == Duration.zero, off);
      await h.dispose(tester);
    });
  }
}
