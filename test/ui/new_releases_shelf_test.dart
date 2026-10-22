import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:codecore/services/releases/release_diff.dart';
import 'package:codecore/ui/screens/home/home_screen.dart';
import 'package:codecore/ui/screens/online/online_album_screen.dart';
import 'package:codecore/ui/screens/releases/new_releases_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/releases_support.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

const _lucio = YtmArtistRef(id: 'UCl', name: 'Lucio Corsi');

void main() {
  late Harness h;
  late FakeChecks checks;

  Future<void> open(WidgetTester tester, {Future<void> Function()? seed}) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: 4);
    checks = FakeChecks(h.db, h.store);
    if (seed != null) await tester.runAsync(seed);
    await h.pump(tester, const HomeScreen(), extraOverrides: [
      checks.override,
      onlineAlbumProvider.overrideWith((ref, id) async => CatalogResult(
            YtmAlbum(browseId: id, title: 'Volevo', artist: _lucio, year: '2026', kindLabel: 'Album', tracks: const []),
            DateTime(2026, 10, 22),
          )),
    ]);
    await _settle(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await h.dispose(tester);
    checks.dispose();
  }

  testWidgets('home has no «Nuove uscite» shelf until something new is found', (tester) async {
    await open(tester);
    expect(find.text('Nuove uscite'), findsNothing);
    await close(tester);
  });

  testWidgets('home shows the shelf with the release; opening it marks it opened and drops the dot',
      (tester) async {
    await open(tester,
        seed: () => seedNewRelease(h.db, _lucio, 'MPREb_1', 'Volevo', kind: ReleaseKind.single));
    expect(find.text('Nuove uscite'), findsOneWidget);
    expect(find.text('Volevo'), findsOneWidget);
    expect(find.text('Lucio Corsi'), findsOneWidget);
    expect(find.text('Singolo · 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-dot-MPREb_1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-release-MPREb_1')));
    await _settle(tester);
    expect(find.byType(OnlineAlbumScreen), findsOneWidget);
    expect(await tester.runAsync(() => checks.releases.countNew()), 0);

    Navigator.of(tester.element(find.byType(OnlineAlbumScreen))).pop();
    await _settle(tester);
    expect(find.byKey(const ValueKey('new-release-MPREb_1')), findsOneWidget, reason: 'it stays on the shelf');
    expect(find.byKey(const ValueKey('new-dot-MPREb_1')), findsNothing);
    await close(tester);
  });

  testWidgets('«Mostra tutte» opens the page of the last 90 days', (tester) async {
    await open(tester, seed: () => seedNewRelease(h.db, _lucio, 'MPREb_1', 'Volevo'));
    await tester.tap(find.text('Mostra tutte'));
    await _settle(tester);
    expect(find.byType(NewReleasesScreen), findsOneWidget);
    await close(tester);
  });

  testWidgets('the top artists card is offered once: «No, grazie» hides it for good', (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('top-artists-card')), findsOneWidget);
    expect(find.textContaining('Vuoi sapere quando escono brani nuovi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('top-artists-no')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('top-artists-card')), findsNothing);
    expect(h.store.releasesTopCardSeen, isTrue);
    expect(h.store.releasesTopArtists, isFalse);
    await close(tester);
  });

  testWidgets('«Attiva» turns the option on and the card goes away', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('top-artists-yes')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('top-artists-card')), findsNothing);
    expect(h.store.releasesTopArtists, isTrue);
    expect(h.store.releasesTopCardSeen, isTrue);
    await close(tester);
  });
}
