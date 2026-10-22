import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/mini_player.dart';
import 'package:codecore/ui/widgets/ring_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  test('progress is clamped and null without a duration', () {
    expect(ringProgress(const Duration(seconds: 30), const Duration(seconds: 60)), 0.5);
    expect(ringProgress(const Duration(seconds: 90), const Duration(seconds: 60)), 1.0);
    expect(ringProgress(Duration.zero, null), isNull);
    expect(ringProgress(const Duration(seconds: 5), Duration.zero), isNull);
  });

  test('unknown duration paints the full arc without dot', () {
    final p = RingPainter(progress: null, arc: Colors.red, rest: Colors.grey, stroke: 3);
    expect(p.shouldRepaint(RingPainter(progress: 0.2, arc: Colors.red, rest: Colors.grey, stroke: 3)), isTrue);
    expect(p.shouldRepaint(RingPainter(progress: null, arc: Colors.red, rest: Colors.grey, stroke: 3)), isFalse);
  });

  testWidgets('the mini-player shows the ring and no linear bar', (tester) async {
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
    expect(find.descendant(of: find.byType(MiniPlayer), matching: find.byType(RingProgress)), findsOneWidget);
    expect(find.descendant(of: find.byType(MiniPlayer), matching: find.byType(LinearProgressIndicator)), findsNothing);
    await h.dispose(tester);
  });
}
