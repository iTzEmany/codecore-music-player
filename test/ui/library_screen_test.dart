import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_entries.dart';
import 'package:codecore/ui/screens/library/library_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/ui/widgets/segmented_blocks.dart';
import 'package:drift/drift.dart' show Value;
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
  Future<Harness> open(WidgetTester tester, {double width = 400, int tracks = 4}) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: tracks);
    if (width >= 840) {
      await h.pump(tester, const LibraryScreen());
    } else {
      await h.pump(tester, const AppShell());
      await tester.tap(find.text('Libreria'));
    }
    await _settle(tester);
    return h;
  }

  testWidgets('blocks filter the list and the count follows', (t) async {
    final h = await open(t);
    expect(find.text('Tutto'), findsOneWidget);
    expect(find.text('Album 0'), findsOneWidget);
    await t.tap(find.text('Album').first);
    await _settle(t);
    expect(find.text('2 album'), findsOneWidget);
    expect(find.text('Artist'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    await t.tap(find.text('Tutto'));
    await _settle(t);
    expect(find.text('Album 0'), findsOneWidget);
    await t.tap(find.byIcon(Icons.grid_view_rounded));
    await _settle(t);
    expect(find.text('Album 0'), findsOneWidget);
    expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
    expect(t.takeException(), isNull);
    await h.dispose(t);
  });

  testWidgets('sort menu switches to A–Z', (t) async {
    final h = await open(t);
    await t.tap(find.text('Recenti'));
    await t.pumpAndSettle();
    await t.tap(find.text('A–Z').last);
    await t.pumpAndSettle();
    await _settle(t);
    expect(find.text('A–Z'), findsOneWidget);
    await h.dispose(t);
  });

  testWidgets('shortcuts only in Tutto, in spec order', (t) async {
    final h = await open(t);
    final fav = t.getRect(find.text('Preferiti'));
    final all = t.getRect(find.text('Tutti i brani'));
    expect(all.left > fav.left || all.top > fav.top, isTrue);
    await t.tap(find.text('Album').first);
    await _settle(t);
    expect(find.text('Preferiti'), findsNothing);
    await h.dispose(t);
  });

  testWidgets('shortcuts are blocks with the icon left of the label', (t) async {
    final h = await open(t, width: 360);
    final icon = t.getRect(find.byIcon(Icons.favorite_rounded));
    final fav = t.getRect(find.text('Preferiti'));
    expect(icon.right, lessThanOrEqualTo(fav.left));
    final favBlock = t.getRect(find.ancestor(
        of: find.text('Preferiti'), matching: find.byType(InkWell)));
    final allBlock = t.getRect(find.ancestor(
        of: find.text('Tutti i brani'), matching: find.byType(InkWell)));
    expect(allBlock.top, favBlock.top);
    await h.dispose(t);
  });

  testWidgets('zero-count shortcuts disappear except Preferiti and Tutti i brani',
      (t) async {
    final h = await open(t);
    expect(find.text('Preferiti'), findsOneWidget);
    expect(find.text('Tutti i brani'), findsOneWidget);
    expect(find.text('Podcast'), findsNothing);
    expect(find.text('Radio'), findsNothing);
    await h.dispose(t);
  });

  testWidgets('A–Z headers follow leadingLetter', (t) async {
    final h = await open(t, tracks: 0);
    var i = 0;
    for (final album in ['Abba', 'Ägypten', '1999', 'Beta']) {
      await h.db.into(h.db.tracks).insert(TracksCompanion.insert(
            path: '/m/x${i++}.mp3',
            title: 'T$i',
            albumKey: 'a|$album',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: i,
            artist: const Value('Zed'),
            album: Value(album),
          ));
    }
    await _settle(t);
    expect(find.text('A'), findsNothing);
    await t.tap(find.text('Recenti'));
    await t.pumpAndSettle();
    await t.tap(find.text('A–Z').last);
    await t.pumpAndSettle();
    await _settle(t);
    // Headers only: covers may also show an initial.
    Finder header(String x) => find.byWidgetPredicate((w) =>
        w is Text && w.data == x && w.style?.color == CcColors.notte.accentSoft);
    for (final x in ['A', 'B', '#', 'Z']) {
      expect(header(x), findsOneWidget, reason: x);
    }
    await h.dispose(t);
  });

  testWidgets('desktop: content reaches the same right edge as the header',
      (t) async {
    final h = await open(t, width: 1600);
    final r = t.getRect(find.byType(SegmentedBlocks<LibraryKind?>));
    final menu = t.getRect(find.byTooltip('Altre azioni'));
    expect(r.right, greaterThanOrEqualTo(menu.right - 2 * CcDims.margin));
    await h.dispose(t);
  });
}
