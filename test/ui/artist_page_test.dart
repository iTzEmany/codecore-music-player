import 'package:codecore/core/constants.dart';
import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:codecore/ui/screens/online/artist_page_screen.dart';
import 'package:codecore/ui/screens/online/artist_page_sections.dart';
import 'package:codecore/ui/widgets/net_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_ytm.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

const _ref = YtmArtistRef(
  id: 'UCpf',
  name: 'Pink Floyd',
  audience: '25.9M ascoltatori mensili',
);

final _full = YtmArtistPage(
  ref: _ref,
  description: 'Una band inglese. ' * 40,
  shelves: [
    YtmSongShelf('Brani più ascoltati', [
      ytmSong('s1', 'Time'),
      ytmSong('s2', 'Money'),
    ], allSongs: const YtmBrowseLink('VLOLAK', null)),
    const YtmReleaseShelf('Album', [
      YtmRelease(browseId: 'MPREb_1', title: 'The Wall', subtitle: '1979'),
    ], more: YtmBrowseLink('MPAD', 'p')),
    const YtmReleaseShelf('Singoli ed EP', [
      YtmRelease(
        browseId: 'MPREb_2',
        title: 'Arnold Layne',
        subtitle: 'Singolo • 1967',
      ),
    ]),
    const YtmArtistShelf('Ai fan potrebbe anche piacere', [
      YtmArtistRef(id: 'UC2', name: 'Roger Waters'),
    ]),
  ],
);

class _CountingCatalog extends FakeCatalog {
  _CountingCatalog() : super((q) async => null);
  final refreshFlags = <bool>[];

  @override
  Future<CatalogResult<YtmArtistPage>> artist(
    String id,
    String hl, {
    bool refresh = false,
  }) async {
    refreshFlags.add(refresh);
    return CatalogResult(_full, DateTime(2026, 10, 22));
  }
}

void main() {
  Future<Harness> open(
    WidgetTester tester,
    Future<CatalogResult<YtmArtistPage>> Function() page, {
    YtmArtistRef artist = _ref,
    int libraryTracks = 0,
  }) async {
    tester.view.physicalSize = const Size(600, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: libraryTracks);
    await h.pump(
      tester,
      ArtistPageScreen(artist: artist),
      extraOverrides: [artistPageProvider.overrideWith((ref, id) => page())],
    );
    await _settle(tester);
    return h;
  }

  double y(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets(
    'sections come in the page order: songs, releases, similar artists, about',
    (tester) async {
      final h = await open(
        tester,
        () async => CatalogResult(_full, DateTime(2026, 10, 22)),
      );
      expect(find.text('25.9M ascoltatori mensili'), findsOneWidget);
      final order = [
        y(tester, 'Brani più ascoltati'),
        y(tester, 'Album'),
        y(tester, 'Singoli ed EP'),
        y(tester, 'Ai fan potrebbe anche piacere'),
        y(tester, 'Informazioni'),
      ];
      expect(order, [...order]..sort());
      expect(
        find.text('Tutti'),
        findsNWidgets(2),
        reason: 'songs and albums have a link; singles do not',
      );
      expect(
        find.text('Nella tua libreria'),
        findsNothing,
        reason: 'no songs of the artist in the library',
      );
      expect(find.byKey(const ValueKey('offline-notice')), findsNothing);
      await h.dispose(tester);
    },
  );

  testWidgets(
    'a missing section is not shown; «Altro» opens the whole biography',
    (tester) async {
      final sparse = YtmArtistPage(
        ref: _ref,
        description: 'Una band inglese. ' * 40,
        shelves: const [
          YtmReleaseShelf('Singoli ed EP', [
            YtmRelease(
              browseId: 'MPREb_2',
              title: 'Arnold Layne',
              subtitle: '1967',
            ),
          ]),
        ],
      );
      final h = await open(
        tester,
        () async => CatalogResult(sparse, DateTime(2026, 10, 22)),
      );
      expect(find.text('Singoli ed EP'), findsOneWidget);
      expect(find.text('Album'), findsNothing);
      expect(find.text('Brani più ascoltati'), findsNothing);

      final collapsed = tester
          .getSize(find.byKey(const ValueKey('about-text')))
          .height;
      await tester.tap(find.byKey(const ValueKey('about-toggle')));
      await _settle(tester);
      expect(
        tester.getSize(find.byKey(const ValueKey('about-text'))).height,
        greaterThan(collapsed),
      );
      await h.dispose(tester);
    },
  );

  testWidgets(
    '«Nella tua libreria» only with the artist\'s songs in the library,',
    (tester) async {
      final mine = await open(
        tester,
        () async => CatalogResult(_full, DateTime(2026, 10, 22)),
        artist: const YtmArtistRef(id: 'UCpf', name: 'Artist'),
        libraryTracks: 2,
      );
      expect(find.text('Nella tua libreria'), findsOneWidget);
      expect(find.text('Song 0'), findsOneWidget);
      await mine.dispose(tester);

      final other = await open(
        tester,
        () async => CatalogResult(_full, DateTime(2026, 10, 22)),
        libraryTracks: 2,
      );
      expect(
        find.text('Nella tua libreria'),
        findsNothing,
        reason: 'the library has songs of «Artist», not of Pink Floyd',
      );
      await other.dispose(tester);
    },
  );

  testWidgets('a top song you already have (found by title) says so', (
    tester,
  ) async {
    final page = YtmArtistPage(
      ref: const YtmArtistRef(id: 'UCpf', name: 'Artist'),
      shelves: [
        YtmSongShelf('Brani più ascoltati', [
          ytmSong('s1', 'Song 0', artist: 'Artist'),
          ytmSong('s2', 'Other'),
        ]),
      ],
    );
    final h = await open(
      tester,
      () async => CatalogResult(page, DateTime(2026, 10, 22)),
      artist: const YtmArtistRef(id: 'UCpf', name: 'Artist'),
      libraryTracks: 2,
    );
    expect(find.text('Già in libreria'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('online header: photo left, follow outlined', (tester) async {
    final h = await open(
      tester,
      () async => CatalogResult(_full, DateTime(2026, 10, 22)),
    );
    final photo = tester.getRect(
      find.byKey(const ValueKey('collection-cover')),
    );
    final name = tester.getRect(find.byKey(const ValueKey('collection-name')));
    expect(photo.right, lessThanOrEqualTo(name.left));
    expect(find.text('25.9M ascoltatori mensili'), findsOneWidget);
    if (kEnableYoutube) {
      expect(find.byKey(const ValueKey('follow-button')), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    }
    await h.dispose(tester);
  });

  testWidgets('online header: no photo, no audience, long name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final artist = YtmArtistRef(id: 'UCx', name: 'N' * 80);
    await h.pump(
      tester,
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 780),
          textScaler: TextScaler.linear(1.5),
        ),
        child: ArtistPageScreen(artist: artist),
      ),
      extraOverrides: [
        artistPageProvider.overrideWith(
          (ref, id) async => CatalogResult(
            YtmArtistPage(ref: artist, shelves: const []),
            DateTime(2026, 10, 22),
          ),
        ),
      ],
    );
    await _settle(tester);
    expect(tester.takeException(), isNull);
    final name = find.byKey(const ValueKey('collection-name'));
    final cover = find.byKey(const ValueKey('collection-cover'));
    expect(name, findsOneWidget);
    expect(cover, findsOneWidget);
    expect(
      tester.getRect(cover).bottom,
      lessThanOrEqualTo(tester.getRect(name).top),
      reason: 'narrow and large text: the cover sits above the name',
    );
    expect(
      find.descendant(
        of: find.byType(ArtistHeader),
        matching: find.byWidgetPredicate((w) => w is NetThumbnail && w.circle),
      ),
      findsOneWidget,
    );
    await h.dispose(tester);
  });

  testWidgets(
    'sections are rows: no sideways lists, three similar artists, plain release line',
    (tester) async {
      final page = YtmArtistPage(
        ref: _ref,
        description: 'Una band inglese. ' * 60,
        shelves: [
          const YtmReleaseShelf('Album', [
            YtmRelease(
              browseId: 'MPREb_1',
              title: 'The Wall',
              subtitle: 'EP • 2025',
            ),
            YtmRelease(browseId: 'MPREb_2', title: 'Animals', subtitle: ''),
          ], more: YtmBrowseLink('MPAD', 'p')),
          YtmArtistShelf('Simili', [
            for (var i = 0; i < 5; i++)
              YtmArtistRef(id: 'UC$i', name: 'Simile $i'),
          ]),
        ],
      );
      final h = await open(
        tester,
        () async => CatalogResult(page, DateTime(2026, 10, 22)),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.horizontal,
        ),
        findsNothing,
      );
      expect(find.text('Tutti'), findsOneWidget);
      expect(find.text('Mostra tutto'), findsNothing);
      expect(find.byKey(const ValueKey('similar-UC2')), findsOneWidget);
      expect(find.byKey(const ValueKey('similar-UC3')), findsNothing);
      expect(find.text('EP, 2025'), findsOneWidget);
      expect(find.text('EP • 2025'), findsNothing);
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('about-text')),
      );
      expect(text.maxLines, 4);
      await tester.ensureVisible(find.byKey(const ValueKey('about-toggle')));
      await tester.tap(find.byKey(const ValueKey('about-toggle')));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('about-text'))).maxLines,
        isNull,
      );
      await h.dispose(tester);
    },
  );

  testWidgets('an old copy is shown with the date it comes from', (
    tester,
  ) async {
    final h = await open(
      tester,
      () async => CatalogResult(_full, DateTime(2026, 10, 20), stale: true),
    );
    expect(find.byKey(const ValueKey('offline-notice')), findsOneWidget);
    expect(find.textContaining('Non in linea, dati del'), findsOneWidget);
    expect(
      find.text('Brani più ascoltati'),
      findsOneWidget,
      reason: 'the page is there as well',
    );
    await h.dispose(tester);
  });

  testWidgets(
    'an unreadable page offers the normal search; «not found» offers no retry',
    (tester) async {
      var h = await open(tester, () async => throw const InnerTubeChanged('x'));
      expect(find.textContaining('non si legge'), findsOneWidget);
      expect(find.text('Cerca i brani di Pink Floyd'), findsOneWidget);
      expect(find.byKey(const ValueKey('error-retry')), findsOneWidget);
      await h.dispose(tester);

      h = await open(tester, () async => throw const ArtistNotFound('UCpf'));
      expect(find.text('Artista non trovato'), findsOneWidget);
      expect(find.byKey(const ValueKey('error-retry')), findsNothing);
      expect(find.byKey(const ValueKey('error-search')), findsNothing);
      await h.dispose(tester);
    },
  );

  testWidgets(
    'pulling the page down asks the catalog again with refresh and reloads',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final catalog = _CountingCatalog();
      final h = await Harness.create(tester);
      await h.pump(
        tester,
        ArtistPageScreen(artist: _ref),
        extraOverrides: [ytmCatalogProvider.overrideWithValue(catalog)],
      );
      await _settle(tester);
      expect(catalog.refreshFlags, [false]);

      await tester.fling(
        find.text('Brani più ascoltati'),
        const Offset(0, 400),
        1000,
      );
      await _settle(tester);
      await _settle(tester);
      expect(catalog.refreshFlags, [
        false,
        true,
        false,
      ], reason: 'refresh, then the provider reads the new copy');
      await h.dispose(tester);
    },
  );
}
