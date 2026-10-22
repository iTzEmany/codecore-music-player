import 'package:codecore/data/repositories/radio_repository.dart';
import 'package:codecore/providers/radio_providers.dart';
import 'package:codecore/services/radio/radio_catalog.dart';
import 'package:codecore/services/radio/radio_station.dart';
import 'package:codecore/ui/screens/home/home_screen.dart';
import 'package:codecore/ui/screens/radio/radio_screen.dart';
import 'package:codecore/ui/screens/library/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

const _a = RadioStation(id: 'a', name: 'Radio Alfa', streamUrl: 'http://radio.test/a');
const _b = RadioStation(id: 'b', name: 'Radio Beta', streamUrl: 'http://radio.test/b');

void main() {
  late Harness h;

  Future<void> open(WidgetTester tester, Widget screen, {List<RadioStation> saved = const []}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 4, radio: true);
    await h.store.writeSettings(h.store.readSettings().copyWith(radioCountry: 'IT', radioRegion: 'lazio'));
    await tester.runAsync(() async {
      for (final s in saved) {
        await RadioRepository(h.db).save(s);
      }
    });
    await h.pump(tester, screen, extraOverrides: [
      radioRefreshProvider.overrideWithValue(() async => false),
      radioCountriesProvider.overrideWith((ref) async => const []),
      nearYouProvider.overrideWith((ref) async => null),
      radioCountryStationsProvider.overrideWith((ref) async => const RadioList([])),
    ]);
    await _settle(tester);
  }

  testWidgets('home: no «Le tue radio» row until a station is saved', (tester) async {
    await open(tester, const HomeScreen());
    expect(find.text('Le tue radio'), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('home: the saved stations are a row and a tap listens with them as the queue',
      (tester) async {
    await open(tester, const HomeScreen(), saved: [_a, _b]);
    expect(find.text('Le tue radio'), findsOneWidget);
    expect(find.text('Radio Beta'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-radio-b')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    expect(h.handler.isRadio, isTrue);
    expect(h.backend.loadedUris.single.uri.toString(), 'http://radio.test/b');
    await h.dispose(tester);
  });

  testWidgets('library: the «Radio» entry counts the saved stations and opens the page',
      (tester) async {
    await open(tester, const LibraryScreen(), saved: [_a, _b]);
    expect(find.text('Radio'), findsOneWidget);
    expect(find.text('2 stazioni salvate'), findsOneWidget);
    await tester.tap(find.text('Radio'));
    await _settle(tester);
    expect(find.byType(RadioScreen), findsOneWidget);
    expect(find.text('Le mie radio'), findsOneWidget);
    await h.dispose(tester);
  });
}
