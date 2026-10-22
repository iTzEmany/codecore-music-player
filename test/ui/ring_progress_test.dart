import 'dart:math' as math;

import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/mini_player.dart';
import 'package:codecore/ui/widgets/ring_progress.dart';
import 'package:flutter/material.dart';
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
}
