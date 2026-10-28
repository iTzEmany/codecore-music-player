// Phase 59.4 / 59.6: the ring and the bar share one drag state and one position;
// a screen reader meets one slider.
import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/ui/screens/jam/jam_seek_bar.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_controls.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/ui/widgets/ring_progress.dart';
import 'package:codecore/ui/widgets/seek_bar.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const _dur = Duration(seconds: 100);

/// Semantics nodes a screen reader treats as sliders.
int _sliders(WidgetTester tester) {
  var n = 0;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isSlider) n++;
    node.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
  return n;
}

void main() {
  group('ring and bar share the drag', () {
    final ringSeeks = <Duration>[];
    final barSeeks = <Duration>[];
    setUp(() {
      ringSeeks.clear();
      barSeeks.clear();
    });

    Future<void> pump(WidgetTester tester) async {
      final pos = ValueNotifier(const Duration(seconds: 10));
      addTearDown(pos.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('it'),
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RingProgress(
                      size: 300,
                      stroke: 12,
                      seekable: true,
                      position: pos,
                      duration: _dur,
                      onSeek: ringSeeks.add,
                      child: const SizedBox.expand(),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 400,
                      child: SeekBar(
                        position: pos,
                        duration: _dur,
                        onSeek: barSeeks.add,
                      ),
                    ),
                    SeekTime(position: pos, duration: _dur),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    double? ringFraction(WidgetTester tester) => tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(RingProgress),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((p) => p.painter)
        .whereType<RingPainter>()
        .first
        .progress;

    testWidgets('dragging the bar moves the ring and the time; seek on release',
        (tester) async {
      await pump(tester);
      expect(find.text('0:10'), findsOneWidget);
      final g = await tester.startGesture(tester.getCenter(find.byType(Slider)));
      await g.moveBy(const Offset(1, 0));
      await tester.pump();
      final f = tester.widget<Slider>(find.byType(Slider)).value / 100000;
      expect(f, closeTo(0.5, 0.1));
      expect(ringFraction(tester), closeTo(f, 1e-9));
      expect(find.text('0:10'), findsNothing, reason: 'the time follows too');
      expect(barSeeks, isEmpty);
      await g.up();
      await tester.pump();
      expect(barSeeks, hasLength(1));
      expect(ringSeeks, isEmpty);
      expect(ringFraction(tester), isNull, reason: 'back on the position');
    });

    testWidgets('dragging the ring moves the bar and the time; seek on release',
        (tester) async {
      await pump(tester);
      final c = tester.getCenter(find.byType(RingProgress));
      // 90 deg on the ring: 115/320 of the track.
      final g = await tester.startGesture(c + const Offset(0, 150));
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value,
          closeTo(100000 * 115 / 320, 2000));
      expect(find.text('0:10'), findsNothing);
      expect(ringSeeks, isEmpty);
      await g.up();
      await tester.pump();
      expect(ringSeeks, hasLength(1));
      expect(barSeeks, isEmpty);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 10000);
    });
  });

  group('one slider for a screen reader', () {
    testWidgets('the player announces only the ring; times are 12 sp or more',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      final h = await Harness.create(tester, tracks: 2);
      final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
      await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
      await h.pump(tester, const NowPlayingScreen(), extraOverrides: [
        durationProvider.overrideWith((_) => Stream.value(_dur)),
      ]);
      final bar = find.descendant(
        of: find.byType(NpSeekRow),
        matching: find.byType(Slider),
      );
      expect(bar, findsOneWidget, reason: 'the bar is drawn');
      // Every other Slider on screen (desktop volume) plus the ring, not the bar.
      expect(_sliders(tester), find.byType(Slider).evaluate().length);
      expect(find.bySemanticsLabel('Posizione nel brano'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('1:40')).style!.fontSize,
        greaterThanOrEqualTo(12),
      );
      handle.dispose();
      await h.dispose(tester);
    });

    testWidgets('the Jam bar, with no seekable ring, stays the one slider',
        (tester) async {
      final handle = tester.ensureSemantics();
      const jam = JamState(
        hostDeviceId: 'h',
        outputDeviceId: 'h',
        currentIndex: 0,
        items: [
          JamItem(id: 1, ownerDeviceId: 'h', title: 'T', durationMs: 100000, ext: 'mp3'),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildThemeFromColors(CcColors.notte, false),
            home: Scaffold(body: JamSeekBar(jam: jam, onSeek: (_) {})),
          ),
        ),
      );
      expect(_sliders(tester), 1);
      expect(
        tester.widget<Text>(find.text('1:40')).style!.fontSize,
        greaterThanOrEqualTo(12),
      );
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
