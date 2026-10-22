import 'package:codecore/ui/widgets/motion.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: child),
      ),
    );

/// The opacity [owner] gives its child (its own FadeTransition, not the page's).
double _opacity(WidgetTester tester, Finder owner) =>
    tester.widget<FadeTransition>(find.descendant(of: owner, matching: find.byType(FadeTransition)).first).opacity.value;

Finder _fades(Finder owner) => find.descendant(of: owner, matching: find.byType(FadeTransition));

void main() {
  test('only the first 12 rows of a list just shown come in', () {
    final since = DateTime(2026, 10, 21, 12);
    expect(EnterOnce.shouldEnter(0, since, since), isTrue);
    expect(EnterOnce.shouldEnter(11, since, since.add(const Duration(milliseconds: 100))), isTrue);
    expect(EnterOnce.shouldEnter(12, since, since), isFalse);
    expect(EnterOnce.shouldEnter(0, since, since.add(const Duration(seconds: 1))), isFalse,
        reason: 'scrolling back later: no movement');
    expect(EnterOnce.shouldEnter(0, null, since), isFalse, reason: 'no scope, no movement');
  });

  testWidgets('a new list: the first row fades in, the 13th is just there', (tester) async {
    await tester.pumpWidget(_app(EntranceScope(
      child: ListView(children: [
        for (var i = 0; i < 14; i++) EnterOnce(index: i, child: SizedBox(height: 10, child: Text('r$i'))),
      ]),
    )));
    final first = find.byType(EnterOnce).first, thirteenth = find.byType(EnterOnce).at(12);
    expect(_opacity(tester, first), lessThan(1));
    expect(_fades(thirteenth), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_opacity(tester, first), 1);
  });

  testWidgets('pressed, a card shrinks a little and comes back', (tester) async {
    await tester.pumpWidget(_app(const Center(child: PressScale(child: SizedBox(width: 50, height: 50, child: Text('c'))))));
    final gesture = await tester.startGesture(tester.getCenter(find.text('c')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.97);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('the heart beats once when it becomes a favourite', (tester) async {
    Widget heart(bool fav, {bool reduce = false}) => _app(Center(child: HeartIcon(favorite: fav)), reduce: reduce);
    double scale() => tester
        .widget<ScaleTransition>(find.descendant(of: find.byType(HeartIcon), matching: find.byType(ScaleTransition)))
        .scale
        .value;
    await tester.pumpWidget(heart(false));
    await tester.pumpWidget(heart(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scale(), greaterThan(1.1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(scale(), 1);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  group('with «Riduci animazioni» nothing moves', () {
    testWidgets('rows, cards, heart, tabs and the mini-player', (tester) async {
      var tab = 0;
      late StateSetter setTab;
      var fav = false;
      await tester.pumpWidget(_app(
        StatefulBuilder(builder: (context, set) {
          setTab = set;
          return Column(children: [
            EntranceScope(child: EnterOnce(index: 0, child: Text('row', key: ValueKey(tab)))),
            const PressScale(child: Text('card')),
            HeartIcon(favorite: fav),
            Expanded(child: TabFade(index: tab, child: Text('tab $tab'))),
            const RiseIn(child: Text('mini')),
          ]);
        }),
        reduce: true,
      ));
      expect(_fades(find.byType(EnterOnce)), findsNothing);
      expect(find.byType(AnimatedScale), findsNothing);
      setTab(() {
        tab = 1;
        fav = true;
      });
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse, reason: 'durations are zero');
      expect(_opacity(tester, find.byType(TabFade)), 1);
      expect(_opacity(tester, find.byType(RiseIn)), 1);
    });
  });

  group('SpinWhilePlaying', () {
    Widget spin(Object key, {bool playing = true, bool reduce = false}) => ProviderScope(
          overrides: [isPlayingProvider.overrideWith((_) => Stream.value(playing))],
          child: _app(SpinWhilePlaying(trackKey: key, child: const SizedBox(width: 10, height: 10)), reduce: reduce),
        );
    final rotation = find.descendant(of: find.byType(SpinWhilePlaying), matching: find.byType(RotationTransition));
    double angle(WidgetTester t) => t.widget<RotationTransition>(rotation).turns.value;

    testWidgets('the cover spin restarts at 0 on a new track', (tester) async {
      await tester.pumpWidget(spin('a'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(angle(tester), closeTo(5 / 30, 0.01));
      await tester.pumpWidget(spin('b'));
      expect(angle(tester), 0);
      await tester.pump(const Duration(seconds: 3));
      expect(angle(tester), greaterThan(0), reason: 'it goes on turning while playing');
    });

    testWidgets('paused, it does not turn', (tester) async {
      await tester.pumpWidget(spin('a', playing: false));
      await tester.pump(const Duration(seconds: 5));
      expect(angle(tester), 0);
    });

    testWidgets('reduce motion: no rotation at all', (tester) async {
      await tester.pumpWidget(spin('a', reduce: true));
      await tester.pump(const Duration(seconds: 5));
      expect(rotation, findsNothing);
    });
  });
}
