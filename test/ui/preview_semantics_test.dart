import 'package:codecore/ui/screens/library/all_tracks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('a track row keeps its long press and offers the preview action', (t) async {
    final sem = t.ensureSemantics();
    try {
      t.view.physicalSize = const Size(400, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await Harness.create(t, tracks: 3);
      await h.pump(t, const AllTracksScreen());
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 500));
      // The row's node is the one with the long press, above the title's node.
      SemanticsNode? node = t.getSemantics(find.text('Song 0').first);
      while (node != null && !node.getSemanticsData().hasAction(SemanticsAction.longPress)) {
        node = node.parent;
      }
      expect(node, isNotNull);
      final data = node!.getSemanticsData();
      expect(data.label, isNot(contains('Anteprima')));
      // The action sits on the cover's node, inside the row's subtree.
      final actions = <String>[];
      void walk(SemanticsNode n) {
        for (final id in n.getSemanticsData().customSemanticsActionIds ?? <int>[]) {
          actions.add(CustomSemanticsAction.getAction(id)!.label!);
        }
        n.visitChildren((c) {
          walk(c);
          return true;
        });
      }
      walk(node);
      expect(actions, contains('Anteprima 20 s'));
      await h.dispose(t);
    } finally {
      sem.dispose();
    }
  });
}
