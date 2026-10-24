import 'package:codecore/ui/widgets/cover_image.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// Labels of every semantics node under the root that carries one.
List<String> _labels(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode n) {
    if (n.label.isNotEmpty) out.add(n.label);
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  // ignore: deprecated_member_use
  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void main() {
  testWidgets('a cover is hidden from the screen reader unless it has a label', (tester) async {
    final h = await Harness.create(tester, tracks: 1);
    final sem = tester.ensureSemantics();
    await h.pump(
      tester,
      const Column(children: [
        CoverImage(coverKey: null, size: 40),
        CoverImage(coverKey: null, size: 40, semanticLabel: 'Big cover'),
      ]),
    );
    expect(_labels(tester), ['Big cover']);
    sem.dispose();
    await h.dispose(tester);
  });

  testWidgets('a track row says title and artist once, the cover adds no node', (tester) async {
    final h = await Harness.create(tester, tracks: 1);
    final t = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!.first;
    final sem = tester.ensureSemantics();
    await h.pump(tester, Scaffold(body: LiveTrackRow(track: t, onTap: () {})));
    final labels = _labels(tester).where((l) => l.contains(t.title)).toList();
    expect(labels, hasLength(1));
    sem.dispose();
    await h.dispose(tester);
  });

  testWidgets('an online track row exposes one node for its title', (tester) async {
    final h = await Harness.create(tester, tracks: 1);
    final t = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!.first.copyWith(id: -1);
    final sem = tester.ensureSemantics();
    await h.pump(tester, Scaffold(body: LiveTrackRow(track: t, onTap: () {})));
    expect(_labels(tester).where((l) => l.contains(t.title)), hasLength(1));
    sem.dispose();
    await h.dispose(tester);
  });
}
