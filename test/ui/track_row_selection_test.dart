import 'dart:ui' show Tristate;

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/selection_providers.dart';
import 'package:codecore/ui/widgets/cover_image.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:codecore/ui/widgets/track_row_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const _key = 'test-list';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late List<Track> tracks;
  late List<int> tapped;

  Future<Harness> build(WidgetTester tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 4);
    tracks = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!;
    tapped = [];
    final ids = [for (final t in tracks) t.id];
    await h.pump(
      tester,
      Scaffold(
        body: ListView(
          children: [
            for (final t in tracks)
              SizedBox(
                height: 64,
                child: LiveTrackRow(
                  track: t,
                  onTap: () => tapped.add(t.id),
                  selection: RowSelection(listKey: _key, visibleIds: ids),
                ),
              ),
          ],
        ),
      ),
    );
    return h;
  }

  Selection selection(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ListView)),
  ).read(selectionProvider(_key));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('a long press on a phone starts a selection with that row',
      (tester) async {
    final h = await build(tester);
    expect(find.byType(SelectionBox), findsNothing);
    final before = tester.getSize(find.byType(TrackRow).first).height;

    await tester.longPress(find.text('Song 1'));
    await settle(tester);
    expect(selection(tester).ids, {tracks[1].id});
    expect(find.byType(SelectionBox), findsNWidgets(4), reason: 'every row shows its box');
    expect(find.byType(CoverImage), findsNothing, reason: 'the box takes the cover\'s place');
    expect(tester.getSize(find.byType(TrackRow).first).height, before);
    expect(tapped, isEmpty);
    await h.dispose(tester);
  });

  testWidgets('while selecting, a tap picks or drops a row instead of playing it',
      (tester) async {
    final h = await build(tester);
    await tester.longPress(find.text('Song 0'));
    await settle(tester);
    await tester.tap(find.text('Song 2'));
    await settle(tester);
    expect(selection(tester).ids, {tracks[0].id, tracks[2].id});
    await tester.tap(find.text('Song 0'));
    await settle(tester);
    expect(selection(tester).ids, {tracks[2].id});
    expect(tapped, isEmpty);
    await tester.tap(find.text('Song 2'));
    await settle(tester);
    expect(selection(tester).active, isFalse);
    expect(find.byType(SelectionBox), findsNothing, reason: 'back to normal');
    await tester.tap(find.text('Song 3'));
    expect(tapped, [tracks[3].id]);
    await h.dispose(tester);
  });

  testWidgets('a picked row is tinted and marked as selected for screen readers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await build(tester);
    await tester.longPress(find.text('Song 1'));
    await settle(tester);
    final box = tester.widget<SelectionBox>(find.byType(SelectionBox).at(1));
    expect(box.selected, isTrue);
    expect(tester.widget<SelectionBox>(find.byType(SelectionBox).at(0)).selected, isFalse);
    final node = tester.getSemantics(find.byType(TrackRow).at(1));
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(node.value, 'Selezionato');
    semantics.dispose();
    await h.dispose(tester);
  });

  testWidgets('no «add to queue» swipe while selecting', (tester) async {
    final h = await build(tester);
    expect(find.byType(Dismissible), findsNWidgets(4));
    await tester.longPress(find.text('Song 1'));
    await settle(tester);
    expect(find.byType(Dismissible), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('Ctrl+click starts a selection and Shift+click extends it to a range',
      (tester) async {
    final h = await build(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text('Song 0'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(selection(tester).ids, {tracks[0].id});
    expect(tapped, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('Song 2'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);
    expect(selection(tester).ids, {tracks[0].id, tracks[1].id, tracks[2].id});
    await h.dispose(tester);
  });

  testWidgets('a row without a selection scope behaves as before', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 1);
    final t = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!.single;
    var taps = 0;
    await h.pump(tester, Scaffold(body: LiveTrackRow(track: t, onTap: () => taps++)));
    await tester.tap(find.text('Song 0'));
    expect(taps, 1);
    expect(find.byType(SelectionBox), findsNothing);
    await h.dispose(tester);
  });
}
