import 'package:codecore/ui/screens/cleanup/hidden_tracks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late Harness h;

  Future<void> open(WidgetTester tester, {required int hidden}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 3);
    await tester.runAsync(() => h.db.customUpdate(
        'UPDATE tracks SET ignored = 1 WHERE title IN (${[for (var i = 0; i < hidden; i++) "'Song $i'"].join(',')})'));
    await h.pump(tester, const HiddenTracksScreen());
    await _settle(tester);
  }

  Future<int> hiddenCount(WidgetTester tester) async =>
      (await tester.runAsync(() => h.db.customSelect('SELECT COUNT(*) AS n FROM tracks WHERE ignored = 1').getSingle()))!
          .data['n']! as int;

  testWidgets('nothing hidden: the empty message', (tester) async {
    await open(tester, hidden: 0);
    expect(find.text('Brani nascosti'), findsOneWidget);
    expect(find.text('Nessun brano nascosto'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('the hidden tracks are listed with the explanation, the visible one is not', (tester) async {
    await open(tester, hidden: 2);
    expect(find.text('Song 0'), findsOneWidget);
    expect(find.text('Song 1'), findsOneWidget);
    expect(find.text('Song 2'), findsNothing);
    expect(find.textContaining('«Ripristina» li rimette al loro posto'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('the ⋮ button restores one track', (tester) async {
    await open(tester, hidden: 2);
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await _settle(tester);
    expect(await hiddenCount(tester), 1);
    expect(find.text('1 brano ripristinato'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('long press picks, select all and «Ripristina» restore several at once', (tester) async {
    await open(tester, hidden: 3);
    await tester.longPress(find.text('Song 0'));
    await _settle(tester);
    expect(find.text('1 selezionato'), findsOneWidget);
    await tester.tap(find.byTooltip('Seleziona tutto'));
    await _settle(tester);
    expect(find.text('3 selezionati'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('restore-selected')));
    await _settle(tester);
    expect(await hiddenCount(tester), 0);
    expect(find.text('3 brani ripristinati'), findsOneWidget);
    expect(find.text('Nessun brano nascosto'), findsOneWidget);
    await h.dispose(tester);
  });
}
