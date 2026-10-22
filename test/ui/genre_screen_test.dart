import 'package:codecore/ui/screens/search/genre_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:codecore/data/db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('genre: title and both pills fit at 360 dp, 200 % text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    await tester.runAsync(
      () => h.db
          .update(h.db.tracks)
          .write(const TracksCompanion(genre: Value('Rock'))),
    );
    await h.pump(
      tester,
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(2.0),
        ),
        child: const GenreScreen(genre: 'Rock'),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('collection-name')), findsOneWidget);
    expect(find.text('Riproduci'), findsOneWidget);
    expect(find.text('Casuale'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('genre header has a name and no cover', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    await tester.runAsync(
      () => h.db
          .update(h.db.tracks)
          .write(const TracksCompanion(genre: Value('Rock'))),
    );
    await h.pump(tester, const GenreScreen(genre: 'Rock'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('collection-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('collection-cover')), findsNothing);
    await h.dispose(tester);
  });
}
