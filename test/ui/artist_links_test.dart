import 'dart:async';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/artist_link_resolver.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/ui/screens/library/artist_screen.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/screens/online/artist_page_screen.dart';
import 'package:codecore/ui/screens/online/artist_picker_sheet.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/shell/desktop_player_bar.dart';
import 'package:codecore/ui/widgets/artist_links.dart';
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

// "A" is in the library, "B" has one YouTube Music page, "C" has two: a choice.
final _resolver = ArtistLinkResolver(
  library: (key) async => key == 'a'
      ? const ArtistSummary(
          key: 'a', name: 'A', trackCount: 1, albumCount: 1)
      : null,
  search: (name) async => name == 'B'
      ? [const YtmArtistRef(id: 'UC1', name: 'B')]
      : name == 'C'
          ? [
              const YtmArtistRef(id: 'UC2', name: 'C'),
              const YtmArtistRef(id: 'UC3', name: 'C'),
            ]
          : [],
);

Future<Harness> _play(WidgetTester tester, String artist, Widget page) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final h = await Harness.create(tester, tracks: 1);
  await tester.runAsync(() => h.db
      .update(h.db.tracks)
      .write(TracksCompanion(artist: Value(artist))));
  final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
  await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
  await h.pump(tester, page, extraOverrides: [
    artistLinkResolverProvider.overrideWithValue(_resolver),
    // The online page would hit the network.
    artistPageProvider.overrideWith((ref, id) => Completer<Never>().future),
  ]);
  await _settle(tester);
  return h;
}

void main() {
  testWidgets('three artists: three zones, each opens its own page',
      (tester) async {
    final h = await _play(tester, 'A, B feat. C', const AppShell());
    final bar = find.byType(DesktopPlayerBar);
    for (final n in ['A', 'B', 'C']) {
      expect(find.descendant(of: bar, matching: find.text(n)), findsOneWidget);
    }
    expect(
        find.descendant(
            of: find.descendant(of: bar, matching: find.byType(ArtistLinks)),
            matching: find.byType(InkWell)),
        findsNWidgets(3));

    await tester.tap(find.descendant(of: bar, matching: find.text('A')));
    await _settle(tester);
    expect(find.byType(ArtistDetailScreen), findsOneWidget);

    await tester.tap(find.descendant(of: bar, matching: find.text('B')));
    await _settle(tester);
    expect(find.byType(ArtistPageScreen), findsOneWidget);

    await tester.tap(find.descendant(of: bar, matching: find.text('C')));
    await _settle(tester);
    expect(find.byType(ArtistPickerSheet), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('an artist with no page shows the message', (tester) async {
    final h = await _play(tester, 'Nobody', const AppShell());
    await tester.tap(find.descendant(
        of: find.byType(DesktopPlayerBar), matching: find.text('Nobody')));
    await _settle(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('one artist: one zone, also in now playing', (tester) async {
    final h = await _play(tester, 'A', const NowPlayingScreen());
    expect(find.byType(ArtistLinks), findsOneWidget);
    expect(find.descendant(
        of: find.byType(ArtistLinks), matching: find.byType(InkWell)),
        findsOneWidget);
    await h.dispose(tester);
  });
}
