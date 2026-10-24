import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/mini_player.dart';
import 'package:codecore/ui/widgets/ring_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

// The horizontal swipe is covered in transitions_characterization_test.dart.
Future<Harness> _shell(WidgetTester t, {double textScale = 1}) async {
  t.view.physicalSize = const Size(360, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final h = await Harness.create(t, tracks: 2);
  final rows = await t.runAsync(() => h.db.select(h.db.tracks).get());
  await t.runAsync(
      () => h.handler.playQueue(rows!.map((r) => r.id).toList(), 0));
  await h.pump(t, const AppShell(), textScale: textScale);
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  for (var i = 0; i < 3; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
  return h;
}

void main() {
  testWidgets('the mini player ring has a 3 dp stroke', (t) async {
    final h = await _shell(t);
    final ring = t.widget<RingProgress>(
        find.descendant(of: find.byType(MiniPlayer), matching: find.byType(RingProgress)));
    expect(ring.stroke, 3);
    await h.dispose(t);
  });

  testWidgets('textScale 2.0 on 360 px: mini player and dock do not overflow',
      (t) async {
    final h = await _shell(t, textScale: 2);
    expect(t.takeException(), isNull);
    expect(find.byType(MiniPlayer), findsOneWidget);
    await h.dispose(t);
  });
}
