import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('now playing builds with a track', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    final ids = rows!.map((t) => t.id).toList();
    await tester.runAsync(() => h.handler.playQueue(ids, 0));
    await h.pump(tester, const NowPlayingScreen());
    expect(find.text('Song 0'), findsOneWidget);
    expect(find.byIcon(Icons.queue_music), findsOneWidget);
    expect(find.byType(Slider), findsWidgets);
    await h.dispose(tester);
  });
}
