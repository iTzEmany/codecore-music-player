// Characterization (38.4): fixes TODAY's behaviour of the synced lyrics, the
// queue sheet and the tag / activity / devices sheets. Whoever changes the
// behaviour updates these tests in the same step.
import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/tag_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/providers/share_hub.dart';
import 'package:codecore/services/share/discovery.dart';
import 'package:codecore/ui/screens/activity/activity_sheet.dart';
import 'package:codecore/ui/screens/devices/devices_sheet.dart';
import 'package:codecore/ui/screens/lyrics/lyrics_view.dart';
import 'package:codecore/ui/screens/now_playing/queue_sheet.dart';
import 'package:codecore/ui/screens/tags/tags_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

// ---- synced lyrics ------------------------------------------------------

/// 40 lines, one every 5 s: "Line 00" at 0:05 ... "Line 39" at 3:20.
final _lrc = [
  for (var i = 0; i < 40; i++)
    '[${(i * 5 + 5) ~/ 60}:${((i * 5 + 5) % 60).toString().padLeft(2, '0')}.00]Line ${i.toString().padLeft(2, '0')}',
].join('\n');

Future<Harness> _pumpLyrics(WidgetTester tester, {bool reducedMotion = false}) async {
  _phone(tester);
  final h = await Harness.create(tester, tracks: 1);
  if (reducedMotion) {
    await tester.runAsync(() => h.store.writeSettings(const AppSettings(reducedMotion: true)));
  }
  final track = (await tester.runAsync(() async {
    await (h.db.update(h.db.tracks)).write(TracksCompanion(lyricsSynced: Value(_lrc)));
    return h.db.select(h.db.tracks).getSingle();
  }))!;
  await h.pump(tester, Scaffold(body: LyricsView(track: track)));
  return h;
}

Future<void> _at(WidgetTester tester, Harness h, int seconds) async {
  h.backend.posC.add(Duration(seconds: seconds));
  await tester.pump();
  await tester.pump();
}

double _opacity(WidgetTester tester, String line) => tester
    .widget<Opacity>(find.ancestor(of: find.text(line), matching: find.byType(Opacity)).first)
    .opacity;

double _offset(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;

// ---- fake hub for the devices sheet ------------------------------------

class _FakeHub extends ShareHubNotifier {
  _FakeHub(this.n);
  final int n;
  @override
  ShareHubState build() => ShareHubState(
        active: true,
        peers: [
          for (var i = 0; i < n; i++)
            Peer(
                id: 'p$i',
                name: 'Dev ${i.toString().padLeft(2, '0')}',
                host: '10.0.0.$i',
                port: 8000,
                platform: 'android'),
        ],
      );
  @override
  Future<void> enter() async {}
  @override
  Future<void> leave() async {}
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200,
      scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).last);
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text(text), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Widget _opener(void Function(BuildContext, WidgetRef) open) => Consumer(
      builder: (context, ref, _) =>
          TextButton(onPressed: () => open(context, ref), child: const Text('open')),
    );

Future<Harness> _pumpTagsSheet(WidgetTester tester, int tags) async {
  _phone(tester);
  final h = await Harness.create(tester, tracks: 1);
  final rows = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
  await tester.runAsync(() async {
    final repo = TagRepository(h.db);
    for (var i = 0; i < tags; i++) {
      await repo.create('Tag ${i.toString().padLeft(2, '0')}');
    }
  });
  await h.pump(tester, _opener((c, ref) => showTagsSheet(c, ref, rows)));
  await tester.tap(find.text('open'));
  await _settle(tester);
  return h;
}

void main() {
  group('synced lyrics', () {
    testWidgets('the line of the position is the bright one, earlier ones are dimmer, later dimmest',
        (tester) async {
      final h = await _pumpLyrics(tester);
      expect(_opacity(tester, 'Line 00'), 0.55, reason: 'before the first timestamp nothing is current');
      await _at(tester, h, 52); // Line 09 starts at 50 s
      expect(_opacity(tester, 'Line 09'), 1.0);
      expect(_opacity(tester, 'Line 08'), 0.55);
      expect(_opacity(tester, 'Line 10'), 0.35);
      await h.dispose(tester);
    });

    testWidgets('tapping a line seeks to its timestamp', (tester) async {
      final h = await _pumpLyrics(tester);
      await tester.tap(find.text('Line 03')); // 20 s
      await tester.pump();
      expect(h.backend.seeks.last, const Duration(seconds: 20));
      await h.dispose(tester);
    });

    // Relies on GlobalKey + Scrollable.ensureVisible over a SingleChildScrollView:
    // expected to need updating with F-30 (39.8).
    testWidgets('the list scrolls by itself to keep the current line in view', (tester) async {
      final h = await _pumpLyrics(tester);
      expect(_offset(tester), 0);
      await _at(tester, h, 105); // Line 20
      await tester.pump(const Duration(milliseconds: 400)); // first tick
      await tester.pump(const Duration(milliseconds: 400));
      expect(_offset(tester), greaterThan(0));
      // ensureVisible(alignment: 0.35): the line's row (8 px padding) sits at 35 % of the viewport.
      expect(tester.getTopLeft(find.text('Line 20')).dy, closeTo(640 * 0.35 + 8, 40));
      await h.dispose(tester);
    });

    testWidgets('with reduced motion the scroll is already final right after the first frame',
        (tester) async {
      final h = await _pumpLyrics(tester, reducedMotion: true);
      await _at(tester, h, 105);
      final o = _offset(tester);
      expect(o, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_offset(tester), o);
      await h.dispose(tester);
    });

    testWidgets('KNOWN DEFECT: the highlight jumps at once while the scroll animates for 300 ms',
        (tester) async {
      final h = await _pumpLyrics(tester);
      await _at(tester, h, 52);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      final before = _offset(tester);
      await _at(tester, h, 105); // far jump: Line 20
      await tester.pump(const Duration(milliseconds: 16)); // starts the ticker
      await tester.pump(const Duration(milliseconds: 100));
      final o1 = _offset(tester);
      // Fixed as it is today: the highlight is final at once (plain Opacity),
      // the scroll is a separate 300 ms animation. A smoother version changes this.
      expect(_opacity(tester, 'Line 20'), 1.0);
      expect(o1, greaterThan(before));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_offset(tester), greaterThan(o1));
      await h.dispose(tester);
    });
  });

  group('queue sheet', () {
    Future<Harness> pumpQueue(WidgetTester tester, {int at = 0}) async {
      _phone(tester);
      final h = await Harness.create(tester, tracks: 6);
      final rows = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
      await tester.runAsync(() => h.handler.playQueue([for (final t in rows) t.id], at));
      final sc = ScrollController();
      addTearDown(sc.dispose);
      await h.pump(tester, Scaffold(body: QueueSheet(scrollController: sc)));
      await _settle(tester);
      return h;
    }

    testWidgets('the current track sits under «In riproduzione», played ones are hidden',
        (tester) async {
      final h = await pumpQueue(tester, at: 2);
      expect(find.text('In riproduzione'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
      expect(find.text('Song 0'), findsNothing);
      expect(find.text('Song 1'), findsNothing);
      expect(find.text('Song 3'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('tapping an upcoming row jumps to it', (tester) async {
      final h = await pumpQueue(tester);
      await tester.tap(find.text('Song 3'));
      await _settle(tester);
      expect(h.handler.currentIndex, 3);
      await h.dispose(tester);
    });

    testWidgets('swiping an upcoming row removes it from the queue', (tester) async {
      final h = await pumpQueue(tester);
      final before = h.handler.queueIds;
      await tester.fling(find.text('Song 3'), const Offset(-300, 0), 1500);
      await _settle(tester);
      await _settle(tester);
      expect(h.handler.queueIds.length, before.length - 1);
      expect(h.handler.queueIds, isNot(contains(before[3])));
      await h.dispose(tester);
    });
  });

  group('sheets with 30 entries on 360x640', () {
    testWidgets('tags sheet: reaches the last tag by scrolling', (tester) async {
      final h = await _pumpTagsSheet(tester, 30);
      expect(find.text('Tag 00'), findsOneWidget);
      await _scrollTo(tester, 'Tag 29');
      await h.dispose(tester);
    });

    testWidgets('activity sheet: reaches the last running activity by scrolling', (tester) async {
      _phone(tester);
      final h = await Harness.create(tester);
      await h.pump(
        tester,
        _opener((c, _) => ActivitySheet.show(c)),
        extraOverrides: [
          activityProvider.overrideWithValue(ActivityState([
            for (var i = 0; i < 30; i++)
              ActivityItem(
                  kind: ActivityKind.download,
                  key: 'dl-$i',
                  name: 'Brano ${i.toString().padLeft(2, '0')}',
                  progress: 0.5,
                  ref: i),
          ], const [])),
        ],
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.text('Download, Brano 00'), findsOneWidget);
      await _scrollTo(tester, 'Download, Brano 29');
      await h.dispose(tester);
    });

    testWidgets('devices sheet: reaches the last nearby device by scrolling', (tester) async {
      _phone(tester);
      final h = await Harness.create(tester);
      await h.pump(
        tester,
        _opener((c, _) => DevicesSheet.show(c)),
        extraOverrides: [shareHubProvider.overrideWith(() => _FakeHub(30))],
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.text('Dev 00'), findsOneWidget);
      await _scrollTo(tester, 'Dev 29');
      await h.dispose(tester);
    });

    testWidgets('with 100 rows not all are built (skip: dopo F-30 (39.x))', (tester) async {
      // Today the synced lyrics are a SingleChildScrollView + Column: every
      // line is built, on screen or not.
      _phone(tester);
      final h = await Harness.create(tester, tracks: 1);
      final lrc = [
        for (var i = 0; i < 100; i++)
          '[${i ~/ 60}:${(i % 60).toString().padLeft(2, '0')}.00]Line $i',
      ].join('\n');
      final track = (await tester.runAsync(() async {
        await (h.db.update(h.db.tracks)).write(TracksCompanion(lyricsSynced: Value(lrc)));
        return h.db.select(h.db.tracks).getSingle();
      }))!;
      await h.pump(tester, Scaffold(body: LyricsView(track: track)));
      expect(find.textContaining('Line ', skipOffstage: false).evaluate().length, lessThan(40));
      expect(find.text('Line 99', skipOffstage: false), findsNothing);
      await h.dispose(tester);
    }, skip: true); // dopo F-30 (39.x) // dopo F-30 (39.x): lazy lists instead of shrinkWrap
  });
}
