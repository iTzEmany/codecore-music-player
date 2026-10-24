import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/ui/widgets/album_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

List<AlbumSummary> _albums(int n) => [
      for (var i = 0; i < n; i++)
        AlbumSummary(
          albumKey: 'a|$i',
          title: 'Album $i',
          artist: 'A',
          variousArtists: false,
          trackCount: 5,
          durationMs: 1000,
          year: 2000 + i,
          coverKey: null,
        ),
    ];

void main() {
  for (final (n, rows) in [(4, true), (5, false)]) {
    testWidgets('$n albums -> ${rows ? 'rows' : 'grid'}', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester);
      await h.pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: AlbumShelf(albums: _albums(n), onOpen: (_) {}),
          ),
        ),
      );
      expect(find.byType(AlbumRow), rows ? findsNWidgets(n) : findsNothing);
      expect(find.byType(AlbumCard), rows ? findsNothing : findsWidgets);
      if (rows) expect(find.text('2000, 5 brani'), findsOneWidget);
      await h.dispose(tester);
    });
  }
}
