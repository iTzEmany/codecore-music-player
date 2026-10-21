import 'dart:async';

import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/ui/screens/online/artist_page_screen.dart';
import 'package:codecore/ui/screens/youtube/youtube_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_ytm.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

class _Search extends _Base {
  @override
  Future<List<YtResult>> search(String query) async => [ytmSong('v1', 'Mother')];

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async =>
      [ytmSong('m1', 'Time', seconds: 413)];
}

class _Base extends Object implements YoutubeService {
  @override
  Future<List<YtResult>> search(String query) async => const [];
  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async => const [];
  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async => const [];
  @override
  Future<List<YtResult>> albumTracks(String albumLink) async => const [];
  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async =>
      const PlaylistListing.empty();
  @override
  Future<List<YtResult>> searchSoundCloud(String query, {int limit = 5}) async => const [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

const _pink = YtmArtistRef(id: 'UCpf', name: 'Pink Floyd', audience: '25.9M monthly audience');

void main() {
  final asked = <String>[];

  Future<Harness> open(WidgetTester tester, Future<YtmArtistRef?> Function(String) top,
      {int submitted = 1, String query = 'pink floyd'}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    asked.clear();
    await h.pump(
      tester,
      Scaffold(body: YoutubeResults(query: query, submitted: submitted)),
      extraOverrides: [
        youtubeServiceProvider.overrideWithValue(_Search()),
        ytmCatalogProvider.overrideWithValue(FakeCatalog(top)),
        artistPageProvider.overrideWith((ref, id) async {
          asked.add(id);
          return CatalogResult(
              YtmArtistPage(ref: _pink, shelves: const []), DateTime(2026, 10, 22));
        }),
      ],
    );
    await _settle(tester);
    return h;
  }

  testWidgets('the card shows when the top result is an artist and opens the artist page', (tester) async {
    final h = await open(tester, (_) async => _pink);
    expect(find.byKey(const ValueKey('artist-card')), findsOneWidget);
    expect(find.text('Artista · 25.9M monthly audience'), findsOneWidget);
    expect(find.text('Mother'), findsOneWidget, reason: 'the results are there as well');

    await tester.tap(find.byKey(const ValueKey('artist-card')));
    await _settle(tester);
    expect(find.byType(ArtistPageScreen), findsOneWidget);
    expect(asked, ['UCpf']);
    await h.dispose(tester);
  });

  testWidgets('no card when the top result is not an artist, or the lookup fails', (tester) async {
    var h = await open(tester, (_) async => null);
    expect(find.byKey(const ValueKey('artist-card')), findsNothing);
    expect(find.text('Mother'), findsOneWidget);
    await h.dispose(tester);

    h = await open(tester, (_) async => throw StateError('offline'));
    expect(find.byKey(const ValueKey('artist-card')), findsNothing);
    expect(find.text('Mother'), findsOneWidget, reason: 'a failed card is never an error on screen');
    await h.dispose(tester);
  });

  testWidgets('the answer to an old search does not put its card on the new one', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final late = Completer<YtmArtistRef?>();
    final overrides = [
      youtubeServiceProvider.overrideWithValue(_Search()),
      ytmCatalogProvider.overrideWithValue(
          FakeCatalog((q) => q == 'pink floyd' ? late.future : Future.value(null))),
    ];
    Widget page(String q, int n) => Scaffold(body: YoutubeResults(query: q, submitted: n));
    await h.pump(tester, page('pink floyd', 1), extraOverrides: overrides);
    await _settle(tester);
    await h.pump(tester, page('mother', 2), extraOverrides: overrides);
    await _settle(tester);

    late.complete(_pink);
    await _settle(tester);
    expect(find.byKey(const ValueKey('artist-card')), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('on a YouTube Music row the artist name opens that artist', (tester) async {
    final h = await open(tester, (_) async => null);
    await tester.tap(find.byKey(const ValueKey('source-youtubeMusic')));
    await _settle(tester);
    expect(find.text('Time'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('artist-link-m1')));
    await _settle(tester);
    expect(find.byType(ArtistPageScreen), findsOneWidget);
    expect(asked, ['UCpf']);
    await h.dispose(tester);
  });
}
