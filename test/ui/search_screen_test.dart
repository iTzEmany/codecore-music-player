import 'package:codecore/core/constants.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/ui_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codecore/providers/library_providers.dart' show SearchQuery;
import 'package:codecore/ui/screens/search/search_screen.dart';
import 'package:codecore/ui/screens/search/search_section_screen.dart';
import 'package:codecore/ui/widgets/segmented_blocks.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/search_input.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('search: typing shows library sections, never starts YouTube', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const SearchScreen());
    await _settle(tester);
    // Empty query: no results yet; the Online chip follows the flag.
    expect(
      find.byType(SegmentedBlocks<bool>),
      kEnableYoutube ? findsOneWidget : findsNothing,
    );
    typeSearch(tester, 'Song 1');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text('Brani'), findsOneWidget);
    // Plain words still search as text (no operator involved).
    Finder row(String title) =>
        find.descendant(of: find.byType(TrackRow), matching: find.text(title));
    expect(row('Song 1'), findsOneWidget);
    expect(row('Song 0'), findsNothing);
    // Typing did not switch to YouTube mode.
    expect(find.text('Cerca un brano o incolla un link'), findsNothing);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('search without matches says so', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const SearchScreen());
    typeSearch(tester, 'zzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text('Nessun risultato in libreria'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('mode is a two-block selector', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 1);
    await h.pump(tester, const SearchScreen());
    await _settle(tester);
    expect(find.byType(SegmentedBlocks<bool>), findsOneWidget);
    await tester.tap(find.text('Online'));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SearchScreen)),
    );
    expect(container.read(searchOnlineProvider), isTrue);
    await h.dispose(tester);
  }, skip: !kEnableYoutube);

  testWidgets('genres are wrapping text pills', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    for (final (i, g) in ['Rock', 'Jazz'].indexed) {
      await h.db
          .into(h.db.tracks)
          .insert(
            TracksCompanion.insert(
              path: '/m/g$i.mp3',
              title: 'G$i',
              albumKey: 'a|b',
              format: 'mp3',
              sizeBytes: 1,
              mtimeMs: 1,
              addedAt: i,
              genre: Value(g),
            ),
          );
    }
    await h.pump(tester, const SearchScreen());
    await _settle(tester);
    expect(find.byType(GridView), findsNothing);
    final rock = tester.getRect(find.text('Rock'));
    final jazz = tester.getRect(find.text('Jazz'));
    expect(rock.height, lessThan(56));
    expect(jazz.top, rock.top, reason: 'they share a row');
    await h.dispose(tester);
  });

  testWidgets('results are rows: no main card, no Tutti under the limits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(tester, const SearchScreen());
    await _settle(tester);
    typeSearch(tester, 'Album');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text('Risultato principale'), findsNothing);
    expect(find.text('Album 0'), findsOneWidget);
    expect(find.text('Album 1'), findsOneWidget);
    expect(
      find.text('Playlist'),
      findsNothing,
      reason: 'empty section vanishes',
    );
    expect(find.text('Tutti'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );
    await h.dispose(tester);
  });

  testWidgets('section screen lists every match for the query', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 4);
    await h.pump(
      tester,
      const SearchSectionScreen(
        query: SearchQuery('album'),
        kind: SearchSectionKind.albums,
      ),
    );
    await _settle(tester);
    expect(find.text('Album 0'), findsOneWidget);
    expect(find.text('Album 1'), findsOneWidget);
    await h.dispose(tester);
  });
}
