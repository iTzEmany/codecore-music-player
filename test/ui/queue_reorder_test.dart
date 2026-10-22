import 'package:codecore/ui/screens/now_playing/queue_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  test('mapDrop anchors on surviving neighbours and cancels a vanished entry', () {
    // Dropped: b a c d (a was dragged below b); then b disappeared.
    final m = mapDrop(key: 'a', dropped: ['b', 'a', 'c', 'd'], live: ['a', 'c', 'd'], first: 1);
    expect(m, isNull, reason: 'already right before c');
    final n = mapDrop(key: 'a', dropped: ['b', 'c', 'a', 'd'], live: ['a', 'b', 'x', 'c', 'd'], first: 1);
    expect(n, (from: 1, to: 4)); // behind c, before d
    expect(mapDrop(key: 'a', dropped: ['b', 'a'], live: ['b'], first: 1), isNull);
  });

  testWidgets('the queue changing during a drag does not break the drop', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 6);
    final rows = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
    final ids = [for (final t in rows) t.id];
    await tester.runAsync(() => h.handler.playQueue(ids, 0));
    await h.pump(tester, Scaffold(body: QueueSheet(scrollController: ScrollController())));
    await _settle(tester);

    final handle = find.byIcon(Icons.drag_handle_rounded).at(0); // Song 1
    final g = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 100));

    // An import adds a track and another one is removed, mid-drag.
    h.handler.addToQueue(ids.first);
    await tester.runAsync(() => h.handler.removeFromQueue(4));
    await _settle(tester);
    await g.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    await _settle(tester);

    expect(tester.takeException(), isNull);
    final order = h.handler.queueIds;
    expect(order.length, 6);
    expect(order.first, ids.first);
    expect(order.indexOf(ids[1]), greaterThan(1), reason: 'Song 1 moved down');

    // The dragged entry vanishes mid-drag: the move is cancelled.
    final before = h.handler.queueIds;
    final g2 = await tester.startGesture(tester.getCenter(find.byIcon(Icons.drag_handle_rounded).at(0)));
    await tester.pump(const Duration(milliseconds: 100));
    await g2.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => h.handler.removeFromQueue(1));
    await _settle(tester);
    await g2.up();
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(h.handler.queueIds.length, before.length - 1);
    await h.dispose(tester);
  });
}
