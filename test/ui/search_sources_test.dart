import 'dart:io';

import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/ui/screens/youtube/youtube_results.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Answers each kind of search differently and remembers what was asked.
class _Sources implements YoutubeService {
  final calls = <String>[];

  YtResult _r(String id, String title, {MediaSource source = MediaSource.youtube}) => YtResult(
        id: id,
        title: title,
        channel: 'Chan',
        duration: const Duration(minutes: 3),
        source: source,
        webpageUrl: source == MediaSource.soundcloud ? 'https://soundcloud.com/c/$id' : null,
      );

  @override
  Future<List<YtResult>> search(String query) async {
    calls.add('youtube:$query');
    return [_r('y1', 'From YouTube')];
  }

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    calls.add('music:$query:$limit');
    return [_r('m1', 'From YouTube Music')];
  }

  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async =>
      const PlaylistListing.empty();

  @override
  Future<List<YtResult>> searchSoundCloud(String query, {int limit = 5}) async {
    calls.add('soundcloud:$query:$limit');
    return [_r('s1', 'From SoundCloud', source: MediaSource.soundcloud)];
  }

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

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester);
    svc = _Sources();
    await h.pump(
      tester,
      const Scaffold(body: YoutubeResults(query: 'daft punk', submitted: 1)),
      extraOverrides: [youtubeServiceProvider.overrideWithValue(svc)],
    );
    await _settle(tester);
  }

  testWidgets('three sources to choose from, YouTube first; it is what is asked by default', (tester) async {
    await open(tester);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('YouTube Music'), findsOneWidget);
    expect(find.text('SoundCloud'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('source-youtube'))).selected, isTrue);
    expect(svc.calls, ['youtube:daft punk']);
    expect(find.text('From YouTube'), findsOneWidget);
    expect(find.byKey(const ValueKey('from-youtube')), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('picking SoundCloud asks SoundCloud again for the same words and marks the rows', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('source-soundcloud')));
    await _settle(tester);

    expect(svc.calls.last, 'soundcloud:daft punk:10');
    expect(find.text('From SoundCloud'), findsOneWidget);
    expect(find.text('From YouTube'), findsNothing);
    expect(find.byKey(const ValueKey('from-soundcloud')), findsOneWidget);
    expect(h.store.readSettings().searchSource, SearchSource.soundcloud, reason: 'remembered');
    await h.dispose(tester);
  });

  testWidgets('YouTube Music searches the songs, ten of them', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('source-youtubeMusic')));
    await _settle(tester);
    expect(svc.calls.last, 'music:daft punk:10');
    expect(find.text('From YouTube Music'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('tapping the source already chosen does not search again', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('source-youtube')));
    await _settle(tester);
    expect(svc.calls, hasLength(1));
    await h.dispose(tester);
  });
}
