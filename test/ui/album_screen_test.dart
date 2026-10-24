import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('album rows show the duration on a 360 px phone', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(
      tester,
      const AlbumDetailScreen(
        album: AlbumSummary(
          albumKey: 'artist|album 0',
          title: 'Album 0',
          artist: 'Artist',
          variousArtists: false,
          trackCount: 2,
          durationMs: 370000,
          year: 2019,
          coverKey: null,
        ),
      ),
    );
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    // Two tracks of 3:05 in album 0.
    expect(find.text('3:05'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });
}
