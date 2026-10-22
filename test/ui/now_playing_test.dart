import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/ui/screens/library/artist_screen.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/motion.dart';
import 'package:codecore/ui/widgets/ring_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('now playing: context, heart in the title row, cards',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    final ids = rows!.map((t) => t.id).toList();
    await tester.runAsync(() => h.handler.playQueue(ids, 0));
    await h.pump(tester, const NowPlayingScreen());
    expect(find.text('Song 0'), findsOneWidget);
    expect(find.text('Artist'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
    expect(find.byType(Slider), findsWidgets);
    // Without a context the header just says «In riproduzione».
    expect(find.text('In riproduzione'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('play context shows the album name', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
    await h.pump(tester, const NowPlayingScreen());
    final container =
        ProviderScope.containerOf(tester.element(find.byType(NowPlayingScreen)));
    container
        .read(playContextProvider.notifier)
        .set(const PlayContext(PlayContextKind.album, 'Album 0'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('In riproduzione da'), findsOneWidget);
    expect(find.text('Album 0'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('tap on the artist opens the artist page in the Library',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
    await h.pump(tester, const AppShell());
    await _settle(tester);
    // Open Now Playing from the mini-player (tap on the title).
    await tester.tap(find.text('Song 0').last);
    await _settle(tester);
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    await tester.tap(find.text('Artist').last);
    await tester.pump(const Duration(milliseconds: 50));
    await _settle(tester);
    expect(find.byType(NowPlayingScreen), findsNothing);
    expect(find.byType(ArtistDetailScreen), findsOneWidget);
    // The artist page sits in the Library tab: bar + mini-player remain.
    expect(find.text('Libreria'), findsWidgets);
    expect(tester.takeException(), isNull);
    await h.dispose(tester);
  });

  testWidgets('the now playing cover sits in a ring', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
    await h.pump(tester, const NowPlayingScreen());
    expect(
        find.descendant(
            of: find.byType(NowPlayingScreen), matching: find.byType(RingProgress)),
        findsOneWidget);
    expect(find.byType(SpinWhilePlaying), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('reduce motion: the player opens without growing and the cover does not spin',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
    await h.pump(tester, const AppShell());
    await _settle(tester);
    await tester.tap(find.text('Song 0').last);
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(NowPlayingScreen), matching: find.byType(ClipRRect)),
        findsNothing);
    expect(
        find.descendant(
            of: find.byType(SpinWhilePlaying), matching: find.byType(RotationTransition)),
        findsNothing);
    await h.dispose(tester);
  });

  testWidgets('the player grows out of the dock', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
    await h.pump(tester, const AppShell());
    await _settle(tester);
    await tester.tap(find.text('Song 0').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final clip = tester.widget<ClipRRect>(
        find.byWidgetPredicate((w) => w is ClipRRect && w.clipper != null));
    final rrect = clip.clipper!.getClip(const Size(400, 900));
    expect(rrect.height, lessThan(900));
    expect(rrect.top, greaterThan(300), reason: 'still near the dock');
    await _settle(tester);
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    await h.dispose(tester);
  });
}
