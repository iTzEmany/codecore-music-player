import 'dart:async';
import 'dart:io';

import 'package:codecore/providers/listen_providers.dart';
import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/providers/ytm_catalog_providers.dart';
import 'package:codecore/services/online/download_index.dart';
import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/ui/screens/youtube/listen_bar.dart';
import 'package:codecore/ui/screens/youtube/online_results.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/app_harness.dart';
import '../support/fake_ytm.dart';
import '../support/fake_backend.dart';

class _Downloads extends DownloadsNotifier {
  final added = <String>[];
  @override
  List<DownloadItem> build() => const [];
  @override
  void add(YtResult r, {String? tag}) => added.add(r.id);
}

class _Youtube implements YoutubeService {
  @override
  Future<List<YtResult>> search(String query) async => const [
        YtResult(id: 'v0', title: 'Mother', channel: 'Pink Floyd', duration: Duration(minutes: 5, seconds: 35)),
        YtResult(id: 'v1', title: 'Time', channel: 'Pink Floyd', duration: Duration(minutes: 7)),
      ];
  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async => const [];
  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async => const PlaylistListing.empty();
  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async => const [];
  @override
  Future<List<YtResult>> albumTracks(String albumLink) async => const [];
  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel, DownloadOptions options = const DownloadOptions()}) =>
      const Stream.empty();
  @override
  Future<String?> toolVersion() async => '2026.08.19';
  @override
  void close() {}
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('«Ascolta» opens the bar; it pauses, downloads and closes', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final dir = Directory.systemTemp.createTempSync('listen');
    addTearDown(() => dir.deleteSync(recursive: true));
    final downloads = _Downloads();
    final players = <FakeBackend>[];
    await h.pump(
      tester,
      const Scaffold(body: OnlineResults(query: 'pink floyd', submitted: 1)),
      extraOverrides: [
        youtubeServiceProvider.overrideWithValue(_Youtube()),
        ytmCatalogProvider.overrideWithValue(FakeCatalog((_) async => null)),
        downloadsProvider.overrideWith(() => downloads),
        downloadIndexProvider.overrideWith((ref) async => DownloadIndex(File(p.join(dir.path, 'd.json')))),
        streamResolverProvider.overrideWithValue((r, {bool fast = true}) async =>
            StreamAddress(Uri.parse('https://media.example/${r.id}'))),
        listenBackendFactoryProvider.overrideWithValue(() {
          final b = FakeBackend();
          players.add(b);
          return b;
        }),
      ],
    );
    await _settle(tester);
    expect(find.byKey(const ValueKey('listen-bar')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('listen-youtube:v0')));
    await _settle(tester);
    final bar = find.byKey(const ValueKey('listen-bar'));
    expect(bar, findsOneWidget);
    expect(find.descendant(of: bar, matching: find.text('Mother')), findsOneWidget);
    expect(players.single.loadedUris.single.uri.toString(), 'https://media.example/v0');
    expect(find.byTooltip('Pausa'), findsNWidgets(2), reason: 'on the row and on the bar');

    await tester.tap(find.descendant(of: bar, matching: find.byTooltip('Pausa')));
    await _settle(tester);
    expect(players.single.playing, isFalse);

    await tester.tap(find.descendant(of: bar, matching: find.byTooltip('Scarica')));
    await _settle(tester);
    expect(downloads.added, ['v0']);

    await tester.tap(find.descendant(of: bar, matching: find.byTooltip('Chiudi')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('listen-bar')), findsNothing);
    expect(players.single.disposed, isTrue);
    await h.dispose(tester);
  });

  testWidgets('the bar buttons keep their positions while resolving, playing and paused', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final dir = Directory.systemTemp.createTempSync('listen');
    addTearDown(() => dir.deleteSync(recursive: true));
    final gate = Completer<StreamAddress>();
    await h.pump(
      tester,
      const Scaffold(body: Column(children: [Expanded(child: SizedBox()), ListenBar()])),
      extraOverrides: [
        downloadIndexProvider.overrideWith((ref) async => DownloadIndex(File(p.join(dir.path, 'd.json')))),
        streamResolverProvider.overrideWithValue((r, {bool fast = true}) => gate.future),
        listenBackendFactoryProvider.overrideWithValue(FakeBackend.new),
      ],
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(ListenBar)));
    final notifier = container.read(listenProvider.notifier);
    const video = YtResult(id: 'x', title: 'T', channel: 'C', duration: Duration(minutes: 3));
    unawaited(notifier.start(video));
    await _settle(tester);
    final close = find.byTooltip('Chiudi'), download = find.byTooltip('Scarica');
    final closeAt = tester.getCenter(close), downloadAt = tester.getCenter(download);

    gate.complete(StreamAddress(Uri.parse('https://media.example/x')));
    await _settle(tester);
    expect(find.byTooltip('Pausa'), findsOneWidget);
    expect(tester.getCenter(close), closeAt);
    expect(tester.getCenter(download), downloadAt);

    await tester.tap(find.byTooltip('Pausa'));
    await _settle(tester);
    expect(find.byTooltip('Riproduci'), findsOneWidget);
    expect(tester.getCenter(close), closeAt);
    expect(tester.getCenter(download), downloadAt);
    await tester.runAsync(notifier.stop);
    await h.dispose(tester);
  });

  testWidgets('a failed «Ascolta» says why, also away from the results page', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    final dir = Directory.systemTemp.createTempSync('listen');
    addTearDown(() => dir.deleteSync(recursive: true));
    await h.pump(
      tester,
      const Scaffold(body: ListenErrorToaster(child: SizedBox())),
      extraOverrides: [
        downloadIndexProvider.overrideWith((ref) async => DownloadIndex(File(p.join(dir.path, 'd.json')))),
        streamResolverProvider.overrideWithValue(
            (r, {bool fast = true}) async => throw const YtException(YtErrorKind.network, 'search timed out')),
      ],
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(ListenErrorToaster)));
    await tester.runAsync(() => container
        .read(listenProvider.notifier)
        .start(const YtResult(id: 'x', title: 'T', channel: 'C', duration: Duration(minutes: 3))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    await h.dispose(tester);
  });
}
