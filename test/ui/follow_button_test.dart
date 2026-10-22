import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/follow_repository.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/ui/screens/releases/follow_button.dart';
import 'package:codecore/ui/screens/releases/followed_artists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/releases_support.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

const _queen = YtmArtistRef(id: 'UCq', name: 'Queen');
const _muse = YtmArtistRef(id: 'UCm', name: 'Muse');

void main() {
  late Harness h;
  late FakeChecks checks;

  Future<void> open(
    WidgetTester tester,
    Widget page, {
    Future<void> Function()? seed,
  }) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester);
    checks = FakeChecks(h.db, h.store);
    if (seed != null) await tester.runAsync(seed);
    await h.pump(tester, page, extraOverrides: [checks.override]);
    await _settle(tester);
  }

  Future<List<FollowedArtist>> rows(WidgetTester tester) async =>
      (await tester.runAsync(() => h.db.select(h.db.followedArtists).get()))!;

  Future<void> close(WidgetTester tester) async {
    await h.dispose(tester);
    checks.dispose();
  }

  testWidgets(
    '«Segui» follows the artist, runs its first check and turns into «Segui già»',
    (tester) async {
      await open(tester, const Scaffold(body: FollowButton(artist: _queen)));
      expect(find.text('Segui'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('follow-button')));
      await _settle(tester);
      expect(find.text('Segui già'), findsOneWidget);
      expect((await rows(tester)).map((r) => r.ytmId), ['UCq']);
      expect(checks.asked, ['UCq']);
      await close(tester);
    },
  );

  testWidgets('stopping asks first; confirming takes the artist off the list', (
    tester,
  ) async {
    await open(tester, const Scaffold(body: FollowButton(artist: _queen)));
    await tester.tap(find.byKey(const ValueKey('follow-button')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('following-button')));
    await _settle(tester);
    expect(find.text('Smettere di seguire Queen?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    expect(find.text('Segui già'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('following-button')));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Non seguire più'));
    await _settle(tester);
    expect(find.text('Segui'), findsOneWidget);
    expect(await rows(tester), isEmpty);
    await close(tester);
  });

  testWidgets('followed artists: empty state', (tester) async {
    await open(tester, const FollowedArtistsScreen());
    expect(find.text('Artisti seguiti (0)'), findsOneWidget);
    expect(
      find.textContaining('Non segui ancora nessun artista'),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets(
    'followed artists: automatic ones are labelled; the bell mutes; a stopped automatic one stays out',
    (tester) async {
      await open(
        tester,
        const FollowedArtistsScreen(),
        seed: () async {
          await checks.follows.follow(_queen);
          await checks.follows.followAuto(_muse);
        },
      );
      expect(find.text('Artisti seguiti (2)'), findsOneWidget);
      expect(find.text('Più ascoltato'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mute-UCq')));
      await _settle(tester);
      expect(
        (await rows(tester)).firstWhere((r) => r.ytmId == 'UCq').muted,
        isTrue,
      );
      expect(find.byTooltip('Riattiva notifiche'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('unfollow-UCm')));
      await _settle(tester);
      expect(find.text('Muse'), findsNothing);
      final muse = (await rows(tester)).firstWhere((r) => r.ytmId == 'UCm');
      expect(
        muse.excluded,
        isTrue,
        reason:
            'kept as excluded so the most listened list does not bring it back',
      );
      await close(tester);
    },
  );

  testWidgets(
    'followed artists: a not found artist says so and «Riprova» clears it',
    (tester) async {
      await open(
        tester,
        const FollowedArtistsScreen(),
        seed: () async {
          await checks.follows.follow(_queen);
          for (var i = 0; i < kMaxNotFound; i++) {
            await checks.follows.markChecked('UCq', error: kArtistNotFound);
          }
        },
      );
      expect(find.text('Non trovato'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('retry-UCq')));
      await _settle(tester);
      expect(find.text('Non trovato'), findsNothing);
      expect((await rows(tester)).single.checksFailed, 0);
      await close(tester);
    },
  );

  testWidgets(
    'followed artists: a name with several matches waits «Da confermare»',
    (tester) async {
      await open(
        tester,
        const FollowedArtistsScreen(),
        seed: () =>
            checks.follows.saveLookup('queen', 'Queen', ambiguous: true),
      );
      expect(find.text('Da confermare'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);
      await close(tester);
    },
  );
}
