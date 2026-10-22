import 'dart:io';

import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/ui/screens/search/search_screen.dart';
import 'package:codecore/ui/screens/youtube/online_results.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_ytm.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Answers each kind of search differently and remembers what was asked.
class _Sources implements YoutubeService {
  final calls = <String>[];

  @override
  Future<List<YtResult>> search(String query) async {
    calls.add('youtube:$query');
    return [
      const YtResult(
          id: 'y1', title: 'From YouTube', channel: 'Chan', duration: Duration(minutes: 3)),
    ];
  }

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    calls.add('music:$query:$limit');
    return [ytmSong('m1', 'From YouTube Music', artist: 'Daft Punk', seconds: 180)];
  }

  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async =>
      const PlaylistListing.empty();

  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async => const [];
  @override
  Future<List<YtResult>> albumTracks(String albumLink) async => const [];
  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel, DownloadOptions options = const DownloadOptions()}) =>
      const Stream.empty();
  @override
  Future<String?> toolVersion() async => null;
  @override
  void close() {}
}

void main() {
  late Harness h;
  late _Sources svc;

  Future<void> open(WidgetTester tester, {int tracks = 2}) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester, tracks: tracks);
    svc = _Sources();
    await h.pump(
      tester,
      const SearchScreen(),
      extraOverrides: [
        youtubeServiceProvider.overrideWithValue(svc),
        ytmCatalogProvider.overrideWithValue(FakeCatalog((_) async => null)),
        noCapEngine,
      ],
    );
    await _settle(tester);
  }

  Future<void> searchOnline(WidgetTester tester, String text) async {
    await tester.tap(find.widgetWithText(ChoiceChip, 'Online'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
  }

  testWidgets('two modes only: In libreria and Online; no SoundCloud, no source to pick first', (tester) async {
    await open(tester);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'In libreria')).selected, isTrue);
    expect(find.widgetWithText(ChoiceChip, 'Online'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Online'));
    await _settle(tester);
    expect(find.text('SoundCloud'), findsNothing);
    expect(find.text('YouTube Music'), findsNothing, reason: 'the filters come with the results');
    expect(svc.calls, isEmpty, reason: 'nothing is asked until the user submits');
    await h.dispose(tester);
  });

  testWidgets('Online asks YouTube Music and YouTube together for the same words, once, and nothing else', (tester) async {
    await open(tester);
    await searchOnline(tester, 'daft punk');
    expect(svc.calls, unorderedEquals(['music:daft punk:10', 'youtube:daft punk']));
    expect(find.text('From YouTube Music'), findsOneWidget);
    expect(find.text('Altri risultati (1)'), findsOneWidget, reason: 'the video of another song is less sure');
    await h.dispose(tester);
  });

  testWidgets('the filter keeps the rows of one source, asks nothing, and a new search starts from «Tutte»', (tester) async {
    await open(tester);
    await searchOnline(tester, 'daft punk');
    await tester.tap(find.byKey(const ValueKey('others-chip')));
    await _settle(tester);
    expect(find.text('From YouTube'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('filter-ytmSong')));
    await _settle(tester);
    expect(find.text('From YouTube Music'), findsOneWidget);
    expect(find.text('From YouTube'), findsNothing);
    expect(svc.calls, hasLength(2));

    await tester.enterText(find.byType(TextField), 'daft punk around');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('filter-all'))).selected, isTrue);
    expect(svc.calls, hasLength(4), reason: 'the new words were asked, both sources');
    await h.dispose(tester);
  });

  testWidgets('«Cerca online» under the library results moves to Online and searches the text', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'Song 1');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    await tester.dragUntilVisible(find.text('Cerca «Song 1» online'), find.byType(ListView).last, const Offset(0, -300));
    await tester.tap(find.text('Cerca «Song 1» online'));
    await _settle(tester);
    expect(svc.calls, contains('music:Song 1:10'));
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Online')).selected, isTrue);
    await h.dispose(tester);
  });

  testWidgets('closing the legal notice dialog leaves the search screen in place', (tester) async {
    // Like the Cerca tab: the screen lives in a nested Navigator, the dialog in the root one.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester);
    await h.pump(
      tester,
      Scaffold(
        body: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const OnlineResults(query: 'daft punk', submitted: 1),
          ),
        ),
      ),
      extraOverrides: [
        youtubeServiceProvider.overrideWithValue(_Sources()),
        ytmCatalogProvider.overrideWithValue(FakeCatalog((_) async => null)),
        noCapEngine,
      ],
    );
    await _settle(tester);
    await tester.tap(find.byType(TextButton)); // "got it" on the first-time notice
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(OnlineResults), findsOneWidget, reason: 'only the dialog is closed');
    await h.dispose(tester);
  });

}
