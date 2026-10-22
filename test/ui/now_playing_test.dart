import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/ui/screens/library/artist_screen.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/motion.dart';
import 'package:codecore/ui/widgets/quality_tag.dart';
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
    await tester.pump();
    expect(find.byType(NowPlayingScreen), findsOneWidget);
    // The grow clip is an ancestor of the page, not a descendant.
    expect(find.byWidgetPredicate((w) => w is ClipRRect && w.clipper != null), findsNothing);
    final route = ModalRoute.of(tester.element(find.byType(NowPlayingScreen)))!;
    expect(route.animation!.status, AnimationStatus.completed, reason: 'the route settled in one frame');
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

  Future<Harness> openPlayer(WidgetTester tester, {bool? desktop}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
    await tester.runAsync(() => h.handler.playQueue([rows!.first.id], 0));
    await h.pump(tester, NowPlayingScreen(desktop: desktop));
    return h;
  }

  testWidgets('symmetry: the top-bar title sits at the screen centre',
      (tester) async {
    // Mobile: car mode + more on the right, back alone on the left.
    final h = await openPlayer(tester, desktop: false);
    expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
    expect(tester.getCenter(find.text('In riproduzione')).dx,
        closeTo(200, 1));
    await h.dispose(tester);
  });

  testWidgets('symmetry: the quality tag does not move when the total toggles',
      (tester) async {
    final h = await openPlayer(tester);
    final before = tester.getCenter(find.byType(QualityTag)).dx;
    // Elapsed and total are both 0:00 here; the total is the last one.
    await tester.tap(find.text('0:00').last);
    await tester.pump();
    expect(find.text('-0:00'), findsOneWidget);
    expect(tester.getCenter(find.byType(QualityTag)).dx, closeTo(before, 0.5));
    await h.dispose(tester);
  });

  testWidgets('symmetry: the sleep chip sits at the centre of the bottom row',
      (tester) async {
    final h = await openPlayer(tester);
    expect(find.text('Dispositivi'), findsOneWidget);
    expect(find.text('Coda'), findsOneWidget);
    expect(tester.getCenter(find.byKey(const Key('np-sleep-chip'))).dx,
        closeTo(200, 1));
    await h.dispose(tester);
  });

  testWidgets('symmetry: the title mirrors the heart and lines up with the track',
      (tester) async {
    final h = await openPlayer(tester);
    final left = tester.getTopLeft(find.text('Song 0')).dx;
    expect(400 - tester.getTopRight(find.byType(HeartIcon)).dx, closeTo(left, 1));
    // Same edge as the elapsed time below the seek bar.
    expect(tester.getTopLeft(find.text('0:00').first).dx, closeTo(left, 1));
    await h.dispose(tester);
  });

  testWidgets('desktop volume row shows the percentage', (tester) async {
    final h = await openPlayer(tester);
    ProviderScope.containerOf(tester.element(find.byType(NowPlayingScreen)))
        .read(volumeProvider.notifier)
        .set(0.7);
    await tester.pump();
    expect(find.text('70%'), findsOneWidget);
    // Mute button and percentage have the same width: the slider is centred.
    expect(tester.getCenter(find.byType(Slider).last).dx, closeTo(200, 1));
    await h.dispose(tester);
    // Linux: the desktop theme shrink-wraps the mute button.
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
