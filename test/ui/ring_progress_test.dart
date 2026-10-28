import 'dart:math' as math;

import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/mini_player.dart';
import 'package:codecore/ui/widgets/ring_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

class _Arc {
  _Arc(this.start, this.sweep, this.color);
  final double start, sweep;
  final Color color;
}

/// Canvas that only records the arcs and circles the ring draws.
class _Rec implements Canvas {
  final arcs = <_Arc>[];
  final dots = <Offset>[];

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) => arcs.add(_Arc(startAngle, sweepAngle, paint.color));

  @override
  void drawCircle(Offset c, double radius, Paint paint) => dots.add(c);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeController implements PlayerController {
  final seeks = <Duration>[];

  @override
  Future<void> seek(Duration position) async => seeks.add(position);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('progress is clamped and null without a duration', () {
    expect(
      ringProgress(const Duration(seconds: 30), const Duration(seconds: 60)),
      0.5,
    );
    expect(
      ringProgress(const Duration(seconds: 90), const Duration(seconds: 60)),
      1.0,
    );
    expect(ringProgress(Duration.zero, null), isNull);
    expect(ringProgress(const Duration(seconds: 5), Duration.zero), isNull);
  });

  test(
    'the painter draws the track, the played arc and the dot at its tip',
    () {
      const start = -math.pi / 4 + (40 * math.pi / 180) / 2;
      const sweep = 2 * math.pi - 40 * math.pi / 180;
      const arc = Color(0xFFF44336), rest = Color(0xFF9E9E9E);
      _Rec paintAt(double? progress) {
        final c = _Rec();
        RingPainter(
          progress: progress,
          arc: arc,
          rest: rest,
          stroke: 3,
        ).paint(c, const Size.square(48));
        return c;
      }

      // Unknown duration: whole arc in accent, no dot.
      var c = paintAt(null);
      expect(c.arcs.map((a) => a.color.toARGB32()), [
        rest.toARGB32(),
        arc.toARGB32(),
      ]);
      expect(c.arcs.map((a) => a.start), [start, start]);
      expect(c.arcs.map((a) => a.sweep), [sweep, sweep]);
      expect(c.dots, isEmpty);

      // Halfway: half the sweep in accent, one dot at the tip.
      c = paintAt(0.5);
      expect(c.arcs.map((a) => a.sweep), [sweep, sweep / 2]);
      expect(c.dots, hasLength(1));
      final r = 24 - 3 * 1.1;
      final tip = start + sweep / 2;
      expect(c.dots.single.dx, closeTo(24 + r * math.cos(tip), 1e-9));
      expect(c.dots.single.dy, closeTo(24 + r * math.sin(tip), 1e-9));

      // Start: no accent arc, the dot waits at the arc's start.
      c = paintAt(0);
      expect(c.arcs.map((a) => a.color.toARGB32()), [rest.toARGB32()]);
      expect(c.dots, hasLength(1));
    },
  );

  testWidgets('the mini-player shows the ring and no linear bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 3);
    await h.pump(tester, const AppShell());
    await tester.tap(find.text('Libreria'));
    await _settle(tester);
    await tester.tap(find.text('Tutti i brani'));
    await _settle(tester);
    await tester.tap(find.text('Song 1').first);
    await _settle(tester);
    expect(
      find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.byType(RingProgress),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );
    await h.dispose(tester);
  });

  group('seekable ring (full player)', () {
    final ctrl = _FakeController();
    Future<void> pump(
      WidgetTester tester, {
      bool seekable = true,
      Widget child = const SizedBox.expand(),
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWithValue(ctrl),
          positionProvider.overrideWith((_) => Stream.value(Duration.zero)),
          durationProvider.overrideWith(
            (_) => Stream.value(const Duration(seconds: 100)),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          home: Center(
            child: RingProgress(
              size: 300,
              stroke: 12,
              seekable: seekable,
              child: child,
            ),
          ),
        ),
      ),
    );

    setUp(ctrl.seeks.clear);

    testWidgets('a tap on the cover goes through the ring', (tester) async {
      var taps = 0;
      await pump(
        tester,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      );
      await tester.tap(find.byType(RingProgress));
      expect(taps, 1);
    });

    testWidgets('dragging on the ring seeks to the position under the finger', (
      tester,
    ) async {
      await pump(tester);
      final c = tester.getCenter(find.byType(RingProgress));
      // Bottom of the ring band: 115 deg past the start of the 320 deg arc.
      final g = await tester.startGesture(c + const Offset(0, 139));
      await g.moveBy(const Offset(0, 4));
      expect(ctrl.seeks, isEmpty, reason: 'seek only on release');
      await g.up();
      expect(ctrl.seeks, hasLength(1));
      expect(ctrl.seeks.single.inMilliseconds / 1000, closeTo(36, 1.5));
    });

    testWidgets('a touch on the cover does not seek', (tester) async {
      await pump(tester);
      final c = tester.getCenter(find.byType(RingProgress));
      await tester.tapAt(c);
      expect(ctrl.seeks, isEmpty);
    });

    testWidgets('right arrow with focus seeks +5 s', (tester) async {
      await pump(tester);
      Focus.of(
        tester.element(
          find
              .descendant(
                of: find.byType(RingProgress),
                matching: find.byType(DecoratedBox),
              )
              .first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(ctrl.seeks.single, const Duration(seconds: 5));
    });

    testWidgets('screen readers get a slider with +/-5 s', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await tester.pump();
      final node = tester.getSemantics(
        find.bySemanticsLabel('Posizione nel brano'),
      );
      expect(node.value, '0:00 / 1:40');
      expect(node.increasedValue, '0:05');
      tester.semantics.increase(find.semantics.byLabel('Posizione nel brano'));
      expect(ctrl.seeks.single, const Duration(seconds: 5));
      handle.dispose();
    });
  });

  testWidgets('live turning off while mounted: the ring starts to follow the player',
      (tester) async {
    Widget ring({required bool live}) => ProviderScope(
      overrides: [
        positionProvider.overrideWith((_) => Stream.value(Duration.zero)),
        durationProvider.overrideWith(
          (_) => Stream.value(const Duration(seconds: 100)),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RingProgress(size: 100, live: live, child: const SizedBox.expand()),
      ),
    );
    await tester.pumpWidget(ring(live: true));
    await tester.pumpWidget(ring(live: false));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
