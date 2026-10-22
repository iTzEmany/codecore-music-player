import 'dart:async';
import 'dart:io';

import 'package:codecore/services/online/query_intent.dart';
import 'package:codecore/services/online/smart_search.dart';
import 'package:codecore/services/online/query_match.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_catalog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'smart_cases.dart';

/// A search call the test answers when it wants.
class _Call<T> {
  final done = Completer<T>();
  CancelToken? cancel;
}

class _FakeYoutube implements YoutubeService {
  final songs = <_Call<List<YtResult>>>[];
  final videos = <_Call<List<YtResult>>>[];

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) {
    final c = _Call<List<YtResult>>();
    songs.add(c);
    return c.done.future;
  }

  @override
  Future<List<YtResult>> search(String query) {
    final c = _Call<List<YtResult>>();
    videos.add(c);
    return c.done.future;
  }

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
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel, DownloadOptions options = const DownloadOptions()}) =>
      const Stream.empty();

  @override
  Future<String?> toolVersion() async => null;

  @override
  void close() {}
}

class _FakeCatalog implements YtmCatalog {
  final cards = <_Call<TopCard?>>[];

  @override
  Future<TopCard?> topCard(String query, String hl, {CancelToken? cancel}) {
    final c = _Call<TopCard?>()..cancel = cancel;
    cards.add(c);
    return c.done.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('$invocation');
}

void main() {
  late SmartCase sigarette;
  late _FakeYoutube youtube;
  late _FakeCatalog catalog;
  late SmartSearch engine;
  late Completer<void> capReached;
  var clock = DateTime(2026, 10, 22, 12);
  var delays = 0;

  setUp(() {
    sigarette = smartCase('lucio corsi sigarette');
    youtube = _FakeYoutube();
    catalog = _FakeCatalog();
    clock = DateTime(2026, 10, 22, 12);
    capReached = Completer<void>();
    delays = 0;
    engine = SmartSearch(
      youtube: youtube,
      catalog: catalog,
      now: () => clock,
      delay: (_) {
        delays++;
        return capReached.future;
      },
    );
  });

  /// Runs a search and collects its states.
  ({List<SmartSearchState> states, StreamSubscription<SmartSearchState> sub}) start(
      String q, {bool refresh = false}) {
    final states = <SmartSearchState>[];
    final sub = engine.run(q, 'en', refresh: refresh).listen(states.add);
    return (states: states, sub: sub);
  }

  Future<void> answerCard() async {
    catalog.cards.last.done.complete(sigarette.card);
    await pumpEventQueue();
  }

  Future<void> answerSongs([int i = -1]) async {
    youtube.songs[i < 0 ? youtube.songs.length - 1 : i].done.complete(sigarette.songs);
    await pumpEventQueue();
  }

  Future<void> answerVideos([int i = -1]) async {
    youtube.videos[i < 0 ? youtube.videos.length - 1 : i].done.complete(sigarette.videos);
    await pumpEventQueue();
  }

  const song = 'InRdKLk1BTU'; // the same video in both lists

  test('both sources before the cap: one block with both, after the waiting state', () async {
    final run = start('lucio corsi sigarette');
    await pumpEventQueue();
    expect(run.states.single.pending, {MediaKind.ytmSong, MediaKind.ytVideo});
    expect(run.states.single.best, isEmpty);

    await answerCard();
    await answerSongs();
    expect(run.states, hasLength(1), reason: 'waits for YouTube');
    await answerVideos();

    expect(run.states, hasLength(2));
    final block = run.states.last;
    expect(block.pending, isEmpty);
    expect(block.intent, SearchIntent.song);
    expect(block.card, isA<TopSong>());
    final top = block.best.first;
    expect(top.primary.id, song);
    expect(top.sources, {MediaKind.ytmSong, MediaKind.ytVideo});
    await run.sub.cancel();
  });

  test('YouTube after the cap: the block with YouTube Music first, then the rest at the end',
      () async {
    final run = start('lucio corsi sigarette');
    await pumpEventQueue();
    await answerCard();
    await answerSongs();
    expect(delays, 1);
    capReached.complete();
    await pumpEventQueue();

    expect(run.states, hasLength(2));
    final early = run.states.last;
    expect(early.pending, {MediaKind.ytVideo});
    expect(early.best.every((r) => r.sources.length == 1), isTrue);
    final shownBest = [for (final r in early.best) r.primary.id];
    final shownOthers = [for (final r in early.others) r.primary.id];

    await answerVideos();
    final late = run.states.last;
    expect(late.pending, isEmpty);
    // What was on screen is where it was; the new rows come after, per block.
    expect([for (final r in late.best) r.primary.id].take(shownBest.length), shownBest);
    expect([for (final r in late.others) r.primary.id].take(shownOthers.length), shownOthers);
    expect(late.best.length + late.others.length, greaterThan(shownBest.length + shownOthers.length));
    expect(late.best.first.primary.id, song);
    expect(late.best.first.sources, hasLength(2), reason: 'the same song merged into its row');
    await run.sub.cancel();
  });

  test('a 429 from YouTube gives a notice and the source is left alone for 5 minutes', () async {
    var run = start('lucio corsi sigarette');
    await pumpEventQueue();
    await answerCard();
    youtube.videos.last.done.completeError(const YtException(YtErrorKind.rateLimited));
    await answerSongs();

    var last = run.states.last;
    expect(last.notices, [const SearchNotice(MediaKind.ytVideo, NoticeKind.rateLimited)]);
    expect(last.best, isNotEmpty);
    expect(last.error, isNull);
    await run.sub.cancel();

    clock = clock.add(const Duration(minutes: 4));
    run = start('mother pink floyd');
    await pumpEventQueue();
    expect(youtube.videos, hasLength(1), reason: 'not asked while paused');
    expect(run.states.first.notices, hasLength(1));
    await run.sub.cancel();

    clock = clock.add(const Duration(minutes: 2));
    run = start('another phrase');
    await pumpEventQueue();
    expect(youtube.videos, hasLength(2), reason: 'asked again after the pause');
    await run.sub.cancel();
  });

  test('every source failing is an error', () async {
    final run = start('lucio corsi sigarette');
    await pumpEventQueue();
    catalog.cards.last.done.completeError(StateError('card'));
    youtube.songs.last.done.completeError(const YtException(YtErrorKind.network));
    youtube.videos.last.done.completeError(const YtException(YtErrorKind.network));
    await pumpEventQueue();

    final last = run.states.last;
    expect(last.error, isA<YtException>());
    expect(last.best, isEmpty);
    expect(last.pending, isEmpty);
    expect(last.notices.map((n) => n.kind), everyElement(NoticeKind.offline));
    await run.sub.cancel();
  });

  test('the same phrase within 10 minutes asks nothing, a refresh or 10 minutes later does',
      () async {
    var run = start('Lucio  Corsi sigarette');
    await pumpEventQueue();
    await answerCard();
    await answerSongs();
    await answerVideos();
    final first = run.states.last;
    await run.sub.cancel();

    clock = clock.add(const Duration(minutes: 9));
    run = start('lucio corsi sigarette');
    await pumpEventQueue();
    expect(youtube.songs, hasLength(1));
    expect(run.states.single.best.first.primary.id, first.best.first.primary.id);
    await run.sub.cancel();

    run = start('lucio corsi sigarette', refresh: true);
    await pumpEventQueue();
    expect(youtube.songs, hasLength(2));
    await run.sub.cancel();

    clock = clock.add(const Duration(minutes: 11));
    run = start('lucio corsi sigarette');
    await pumpEventQueue();
    expect(youtube.songs, hasLength(3));
    await run.sub.cancel();
  });

  test('a new search drops the late answers of the old one and cancels its card', () async {
    final old = start('lucio corsi sigarette');
    await pumpEventQueue();
    final oldCard = catalog.cards.last;
    await old.sub.cancel();
    expect(oldCard.cancel!.isCancelled, isTrue);

    final fresh = start('pink floyd mother');
    await pumpEventQueue();
    // The old search finally answers.
    await answerSongs(0);
    await answerVideos(0);
    oldCard.done.complete(sigarette.card);
    await pumpEventQueue();
    expect(old.states, hasLength(1));
    expect(fresh.states.single.best, isEmpty);
    await fresh.sub.cancel();
  });

  test('a playlist address is not searched; a video address asks YouTube only', () async {
    final list = start('https://www.youtube.com/playlist?list=PLabc123');
    await pumpEventQueue();
    expect(list.states.single.queryKind, QueryKind.listing);
    expect(list.states.single.listingUrl, contains('PLabc123'));
    expect(youtube.songs, isEmpty);
    expect(youtube.videos, isEmpty);

    final video = start('https://youtu.be/InRdKLk1BTU');
    await pumpEventQueue();
    expect(youtube.songs, isEmpty);
    expect(catalog.cards, isEmpty);
    youtube.videos.single.done.complete([sigarette.videos.first]);
    await pumpEventQueue();
    expect(video.states.last.best.single.primary.id, song);
    await list.sub.cancel();
    await video.sub.cancel();
  });
}
