import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:codecore/core/network_kind.dart';
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/follow_repository.dart';
import 'package:codecore/data/repositories/release_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_artist_parser.dart';
import 'package:codecore/services/releases/release_check_controller.dart';
import 'package:codecore/services/releases/release_checker.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

YtmArtistPage page(String artist) {
  final p = parseArtistPage(
      jsonDecode(File('test/fixtures/innertube/ytm_artist_releases.json').readAsStringSync()) as Map, artist);
  return YtmArtistPage(ref: p.ref, shelves: [
    for (final s in p.shelves.whereType<YtmReleaseShelf>())
      YtmReleaseShelf(s.title, [
        for (final r in s.releases)
          YtmRelease(browseId: '${r.browseId}_$artist', title: r.title, subtitle: r.subtitle),
      ]),
  ]);
}

Future<void> settle([int ms = 40]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late AppDatabase db;
  late FollowRepository follows;
  late ReleaseRepository releases;
  late SettingsStore store;
  late DateTime now;
  late List<String> asked;
  late int autoFollowRuns;
  late List<List<FreshRelease>> notified;
  late NetworkKind net;
  late StreamController<void> netChanges;
  late Future<void> Function(String id) gate;
  late Object Function(String id) answer;
  late ReleaseCheckController c;

  ReleaseCheckController build({
    Duration startDelay = const Duration(milliseconds: 100),
    Duration every = const Duration(milliseconds: 100),
  }) =>
      ReleaseCheckController(
        store: store,
        follows: follows,
        network: () async => net,
        networkChanges: netChanges.stream,
        buildChecker: () => ReleaseChecker(
          (id) async {
            asked.add(id);
            await gate(id);
            final a = answer(id);
            if (a is YtmArtistPage) return a;
            throw a;
          },
          follows,
          releases,
          now: () => now,
          wait: (_) async {},
        ),
        autoFollow: () async => autoFollowRuns++,
        notify: (f) async => notified.add(f),
        now: () => now,
        startDelay: startDelay,
        every: every,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = SettingsStore(await SharedPreferences.getInstance());
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 22, 9);
    follows = FollowRepository(db, now: () => now.millisecondsSinceEpoch);
    releases = ReleaseRepository(db, now: () => now.millisecondsSinceEpoch);
    asked = [];
    autoFollowRuns = 0;
    notified = [];
    net = const NetworkKind();
    netChanges = StreamController<void>.broadcast();
    gate = (_) async {};
    answer = (id) => page(id);
    for (final id in ['UC1', 'UC2']) {
      await follows.follow(YtmArtistRef(id: id, name: 'Artist $id'));
    }
    c = build();
  });
  tearDown(() async {
    c.dispose();
    await netChanges.close();
    await db.close();
  });

  test('nothing before the start delay; the round runs after it, then every hour only once a day', () async {
    c.start();
    await settle(50);
    expect(asked, isEmpty);
    await settle(120);
    expect(asked, ['UC1', 'UC2']);
    expect(store.releasesLastRunAt, now.millisecondsSinceEpoch);

    // Many hourly looks later, still the same day: no new round.
    await settle(350);
    expect(asked, hasLength(2));

    // A day later the next look runs it again.
    now = now.add(const Duration(hours: 25));
    await settle(150);
    expect(asked, hasLength(4));
    expect(store.releasesLastRunAt, now.millisecondsSinceEpoch);
  });

  test('a 429 stores retryAt; no round before it, one after it', () async {
    answer = (id) => const YtException(YtErrorKind.rateLimited, 'HTTP 429');
    c.start();
    await settle(200);
    expect(asked, ['UC1']);
    expect(store.releasesRetryAt, now.add(const Duration(hours: 6)).millisecondsSinceEpoch);
    expect(store.releasesLastRunAt, isNull);

    answer = (id) => page(id);
    now = now.add(const Duration(hours: 5));
    await settle(250);
    expect(asked, ['UC1']);
    expect(await c.checkNow(), isNull); // «Controlla ora» does not skip a pause either

    now = now.add(const Duration(hours: 2));
    await settle(150);
    expect(asked, ['UC1', 'UC1', 'UC2']);
    expect(store.releasesRetryAt, isNull);
    expect(store.releasesLastRunAt, now.millisecondsSinceEpoch);
  });

  test('a round stops when the network goes away; it does not count as made', () async {
    final first = Completer<void>();
    gate = (id) => id == 'UC1' ? first.future : Future.value();
    c.start();
    final run = c.checkNow();
    await settle(20);
    expect(c.running.value, isTrue);
    net = const NetworkKind(online: false);
    netChanges.add(null);
    await settle(20);
    first.complete();
    final out = await run;
    expect(out!.stoppedBy, CheckStop.cancelled);
    expect(asked, ['UC1']);
    expect(store.releasesLastRunAt, isNull);
    expect(c.running.value, isFalse);
  });

  test('turning «Solo su Wi-Fi» on while on mobile data stops the running round', () async {
    net = const NetworkKind(metered: true);
    final first = Completer<void>();
    gate = (id) => id == 'UC1' ? first.future : Future.value();
    final run = c.checkNow();
    await settle(20);
    await store.writeReleasesUnmeteredOnly(true);
    await c.optionsChanged();
    first.complete();
    expect((await run)!.stoppedBy, CheckStop.cancelled);
    expect(asked, ['UC1']);
  });

  test('«Solo su Wi-Fi» on a metered network: no round at all', () async {
    net = const NetworkKind(metered: true);
    await store.writeReleasesUnmeteredOnly(true);
    expect(await c.checkNow(), isNull);
    expect(asked, isEmpty);
  });

  test('the most listened are followed only with the option on, before the checks', () async {
    await c.checkNow();
    expect(autoFollowRuns, 0);
    await store.writeReleasesTopArtists(true);
    await c.checkNow();
    expect(autoFollowRuns, 1);
  });

  test('with no artists nothing runs, unless «Più ascoltati» is on (it may find some)', () async {
    await db.customStatement('DELETE FROM followed_artists');
    expect(await c.checkNow(), isNull);
    expect(autoFollowRuns, 0);
    await store.writeReleasesTopArtists(true);
    await c.checkNow();
    expect(autoFollowRuns, 1);
    expect(asked, isEmpty);
  });

  test('checkArtist checks just that artist (first check: everything seen)', () async {
    final out = await c.checkArtist('UC2');
    expect(asked, ['UC2']);
    expect(out!.checked, 1);
    expect(out.fresh, isEmpty);
    expect((await follows.get('UC2'))!.lastCheckedAt, isNotNull);
    expect((await follows.get('UC1'))!.lastCheckedAt, isNull);
    expect(store.releasesLastRunAt, isNull); // not a round

    await store.writeReleasesRetryAt(now.add(const Duration(hours: 1)).millisecondsSinceEpoch);
    expect(await c.checkArtist('UC1'), isNull);
  });

  test('news are announced once a day, without muted artists, and only if enabled', () async {
    await c.checkNow(); // first round: all seen
    expect(notified, isEmpty);
    await follows.setMuted('UC2', true);
    await db.customStatement("DELETE FROM artist_releases WHERE title = 'Patient Zero'");
    now = now.add(const Duration(hours: 25));
    await c.checkNow();
    expect(notified, hasLength(1));
    expect(notified.single.map((f) => f.artist.ytmId).toSet(), {'UC1'});

    // Same day, another novelty: no second notification.
    await db.customStatement("DELETE FROM artist_releases WHERE title = 'Patient Zero'");
    await c.checkNow();
    expect(notified, hasLength(1));

    // Next day with notifications off: none.
    await store.writeReleasesNotify(false);
    await db.customStatement("DELETE FROM artist_releases WHERE title = 'Patient Zero'");
    now = now.add(const Duration(hours: 25));
    await c.checkNow();
    expect(notified, hasLength(1));
  });
}
