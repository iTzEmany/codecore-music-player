import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/ui/screens/car/car_mode_screen.dart';
import 'package:codecore/ui/screens/car/car_playlists_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Playlist _pl(int id, int created) => Playlist(id: id, name: 'P$id', createdAt: created, uuid: 'u$id', updatedAt: created);

void _phone(WidgetTester tester, {double scale = 1}) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('nothing playing: says so, offers Exit, controls are big', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester);
    await h.pump(tester, const CarModeScreen());
    expect(find.text('Niente in riproduzione'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
    final play = tester.getSize(find.ancestor(of: find.byTooltip('Riproduci'), matching: find.byType(SizedBox)).first);
    expect(play.width, greaterThanOrEqualTo(96));
    expect(play.height, greaterThanOrEqualTo(96));
    await h.dispose(tester);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('a track is shown with big buttons at text ×$scale, without overflow', (tester) async {
      _phone(tester, scale: scale);
      final h = await Harness.create(tester, tracks: 2);
      final ids = (await tester.runAsync(() => h.db.select(h.db.tracks).get()))!.map((t) => t.id).toList();
      await tester.runAsync(() => h.handler.playQueue(ids, 0));
      await h.pump(tester, const CarModeScreen());
      await _settle(tester);
      expect(find.text('Song 0'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
      for (final tip in ['Brano precedente', 'Brano successivo', 'Pausa']) {
        final box = tester.getSize(find.ancestor(of: find.byTooltip(tip), matching: find.byType(SizedBox)).first);
        expect(box.shortestSide, greaterThanOrEqualTo(96), reason: tip);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Brano successivo'));
      await _settle(tester);
      expect(find.text('Song 1'), findsOneWidget);
      await h.dispose(tester);
    });
  }

  testWidgets('Playlist opens a sheet with favourites first', (tester) async {
    _phone(tester);
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const CarModeScreen());
    await tester.tap(find.byTooltip('Playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Preferiti'), findsOneWidget);
    await h.dispose(tester);
  });

  test('recentPlaylists: empty ones dropped, newest activity first, at most 5', () {
    PlaylistSummary p(int id, int created, int count, [int? played]) => PlaylistSummary(
        _pl(id, created), count, null, played);
    final list = [
      p(1, 100, 3), p(2, 200, 0), p(3, 50, 2, 900), p(4, 300, 1),
      p(5, 10, 1), p(6, 20, 1), p(7, 30, 1),
    ];
    final r = recentPlaylists(list);
    expect(r.map((e) => e.playlist.id), [3, 4, 1, 7, 6]);
  });
}
