import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/ui/screens/lyrics/lyrics_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('plain lyrics and stored trivia are shown', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 1);
    await tester.runAsync(() async {
      await (h.db.update(h.db.tracks)).write(const TracksCompanion(
        lyricsPlain: Value('Hello darkness\nmy old friend'),
        curiosities: Value('A famous song.\nhttps://en.wikipedia.org/wiki/X'),
      ));
      final rows = await h.db.select(h.db.tracks).get();
      await h.handler.playQueue([rows.single.id], 0);
    });
    await h.pump(tester, const LyricsScreen());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Hello darkness'), findsOneWidget);
    expect(find.text('Fonte: Wikipedia (CC BY-SA)'), findsOneWidget);
    expect(find.text('A famous song.'), findsOneWidget);
    await h.dispose(tester);
  });
}
