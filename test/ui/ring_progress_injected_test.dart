import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/ui/widgets/ring_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// RingProgress driven by an injected position, duration and onSeek (the Jam
// way): no player provider is overridden, so any read of one would throw.
void main() {
  final pos = ValueNotifier(const Duration(seconds: 25));
  final seeks = <Duration>[];

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: Center(
          child: RingProgress(
            size: 300,
            stroke: 12,
            seekable: true,
            position: pos,
            duration: const Duration(seconds: 100),
            onSeek: seeks.add,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );

  RingPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(RingProgress),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as RingPainter;

  setUp(() {
    seeks.clear();
    pos.value = const Duration(seconds: 25);
  });

  testWidgets('the painter follows the injected position without a rebuild', (
    tester,
  ) async {
    await pump(tester);
    final before = painter(tester);
    expect(ringProgress(before.position!.value, before.duration), 0.25);
    pos.value = const Duration(seconds: 50);
    await tester.pump();
    expect(identical(painter(tester), before), isTrue);
    expect(ringProgress(before.position!.value, before.duration), 0.5);
  });

  testWidgets('release on the ring sends onSeek, keys step 5 s', (
    tester,
  ) async {
    await pump(tester);
    final c = tester.getCenter(find.byType(RingProgress));
    // 90 deg (bottom) on the band is 115/320 of the track.
    final g = await tester.startGesture(c + const Offset(0, 139));
    expect(seeks, isEmpty, reason: 'seek only on release');
    await g.up();
    expect(seeks.single.inSeconds, inInclusiveRange(34, 37));

    seeks.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(seeks.single, const Duration(seconds: 30));
  });

  testWidgets('the screen-reader slider shows the injected position', (
    tester,
  ) async {
    final h = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Posizione nel brano')).value,
      '0:25 / 1:40',
    );
    h.dispose();
  });
}
