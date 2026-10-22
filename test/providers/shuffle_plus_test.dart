import 'dart:async';
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/online_entries.dart';
import 'package:codecore/services/import/track_matcher.dart';
import 'package:codecore/services/online/download_index.dart';
import 'package:codecore/services/online/innertube_client.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_radio_service.dart';
import 'package:codecore/services/shuffle_plus/seed_index.dart';
import 'package:codecore/services/shuffle_plus/seed_resolver.dart';
import 'package:codecore/services/shuffle_plus/shuffle_host.dart';
import 'package:codecore/services/shuffle_plus/shuffle_plus_controller.dart';
import 'package:codecore/services/shuffle_plus/suggestion_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

final radioJson =
    File('test/fixtures/innertube/ytm_radio.json').readAsStringSync();

class _Adapter implements HttpClientAdapter {
  int status = 200;
  final sent = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    sent.add(o);
    return ResponseBody.fromString(status == 200 ? radioJson : '{}', status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _Host implements ShuffleHost {
  _Host(this.queueIds, this.sourceIds);

  @override
  final List<int> queueIds;
  @override
  List<int>? sourceIds;
  @override
  int currentIndex = 0;
  @override
  bool shuffleEnabled = true;
  @override
  bool isPlaying = true;

  final _changes = StreamController<void>.broadcast(sync: true);
  final _pos = StreamController<Duration>.broadcast(sync: true);
  final _dur = StreamController<Duration?>.broadcast(sync: true);
  final _fail = StreamController<PlaybackFailure>.broadcast(sync: true);

  @override
  Stream<void> get changes => _changes.stream;
  @override
  Stream<Duration> get positionStream => _pos.stream;
  @override
  Stream<Duration?> get durationStream => _dur.stream;
  @override
  Stream<PlaybackFailure> get failures => _fail.stream;

  @override
  void insertAt(int index, int id) {
    queueIds.insert(index, id);
    _changes.add(null);
  }

  @override
  Future<void> removeQueueId(int id) async {
    final i = queueIds.indexOf(id);
    if (i < 0) return;
    queueIds.removeAt(i);
    if (i < currentIndex) currentIndex--;
    _changes.add(null);
  }

  /// The current song plays to its end and the next one starts.
  void finishAndAdvance({bool toTheEnd = true}) {
    _dur.add(const Duration(minutes: 3));
    _pos.add(toTheEnd ? const Duration(minutes: 3) : const Duration(seconds: 5));
    currentIndex++;
    _changes.add(null);
  }

  void change() => _changes.add(null);
  void fail() => _fail.add(const PlaybackFailure('x', PlaybackFailureReason.onlineUnavailable));
}

Track track(int id) => Track(
      id: id,
      path: '/m/$id.mp3',
      title: 'Song $id',
      artist: 'Rock Band',
      genre: 'Rock',
      albumKey: 'k',
      durationMs: 200000,
      format: 'mp3',
      sizeBytes: 1,
      mtimeMs: 1,
      hasCover: false,
      isFavorite: false,
      enrichStatus: 0,
      userEdited: false,
      missing: false,
      ignored: false,
      kind: 0,
      addedAt: 1,
      playCount: 0,
    );

void main() {
  late Directory dir;
  late DateTime now;
  late _Adapter adapter;
  late _Host host;
  late OnlineEntries online;
  late SuggestionLog log;
  late ShufflePlusController controller;
  late ShufflePlusConfig cfg;
  var jam = false;
  var metered = false;
  var searches = 0;
  Future<void> Function(YtResult) prepareHook = (_) async {};
  final prepared = <String>[];
  const library = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await pumpEventQueue();
    }
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('shuffle_plus');
    addTearDown(() => dir.deleteSync(recursive: true));
    now = DateTime.utc(2026, 1, 1, 12);
    adapter = _Adapter();
    jam = false;
    metered = false;
    searches = 0;
    prepared.clear();
    prepareHook = (r) async => prepared.add(r.id);
    cfg = const ShufflePlusConfig(enabled: true);
    host = _Host([...library], [...library]);
    online = OnlineEntries();
    log = SuggestionLog(
      file: () async => File(p.join(dir.path, 'suggestions.json')),
      now: () => now,
      writeDelay: const Duration(days: 1),
    );
    final downloads = DownloadIndex(File(p.join(dir.path, 'downloads.json')));
    for (final id in library) {
      await downloads.add('dl$id', '/m/$id.mp3');
    }
    final client = InnerTubeClient(Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter);
    controller = ShufflePlusController(
      host: host,
      online: online,
      log: log,
      resolver: SeedResolver(
        downloads: downloads,
        index: SeedIndex(file: () async => File(p.join(dir.path, 'seeds.json'))),
        searchSongs: (q) async {
          searches++;
          return const [];
        },
      ),
      radio: YtmRadioService(client, _NoMix(), now: () => now),
      config: () => cfg,
      jamActive: () => jam,
      isMetered: () async => metered,
      toolAvailable: () async => true,
      loadTracks: (ids) async => [for (final id in ids) track(id)],
      loadLibrary: () async => LibraryIndex(const []),
      hasDownload: (_) => false,
      prepare: (r) => prepareHook(r),
      now: () => now,
    );
    addTearDown(controller.dispose);
  });

  /// What plays, in order, for [songs] steps: true = a suggestion.
  Future<List<bool>> play(int songs) async {
    final seen = <bool>[];
    for (var i = 0; i < songs; i++) {
      seen.add(isOnlineId(host.queueIds[host.currentIndex]));
      host.finishAndAdvance();
      await settle();
    }
    return seen;
  }

  test('with the option off nothing is asked and nothing is inserted', () async {
    cfg = const ShufflePlusConfig();
    controller.start();
    await settle();
    expect(adapter.sent, isEmpty);
    expect(searches, 0);
    expect(host.queueIds, library);
  });

  test('no request in a Jam, on a metered network, without shuffle, in pause', () async {
    jam = true;
    controller.start();
    await settle();
    jam = false;
    metered = true;
    controller.poke();
    await settle();
    metered = false;
    host.shuffleEnabled = false;
    controller.poke();
    await settle();
    host.shuffleEnabled = true;
    host.isPlaying = false;
    controller.poke();
    await settle();
    expect(adapter.sent, isEmpty);
    expect(host.queueIds, library);
    host.isPlaying = true;
    controller.poke();
    await settle();
    expect(adapter.sent, hasLength(1), reason: 'all conditions met');
  });

  test('metered network is fine when «Solo su Wi-Fi» is off', () async {
    metered = true;
    cfg = const ShufflePlusConfig(enabled: true, unmeteredOnly: false);
    controller.start();
    await settle();
    expect(adapter.sent, hasLength(1));
  });

  test('a list shorter than 5 songs gets plain shuffle', () async {
    host.sourceIds = [1, 2, 3, 4];
    controller.start();
    await settle();
    expect(adapter.sent, isEmpty);
  });

  test('one suggestion every 4 songs, and a passed one leaves the queue', () async {
    controller.start();
    await settle();
    final seen = await play(9);
    expect(seen, [false, false, false, true, false, false, false, true, false]);
    expect(host.queueIds.where(isOnlineId).length, lessThanOrEqualTo(1));
    final passed = host.queueIds.take(host.currentIndex).where(isOnlineId);
    expect(passed, isEmpty, reason: 'passed suggestions are taken out');
    expect(adapter.sent, hasLength(1), reason: 'one radio feeds many suggestions');
  });

  test('a suggestion enters the queue only after its address is ready', () async {
    final gate = Completer<void>();
    prepareHook = (r) async {
      prepared.add(r.id);
      await gate.future;
    };
    controller.start();
    await settle();
    expect(prepared, hasLength(1));
    expect(host.queueIds, library, reason: 'address not ready: nothing queued');
    expect(log.recent, isEmpty);
    gate.complete();
    await settle();
    expect(host.queueIds.where(isOnlineId), hasLength(1));
  });

  test('a failed address tries the next candidate, no entry for the failed one', () async {
    var calls = 0;
    prepareHook = (r) async {
      prepared.add(r.id);
      if (calls++ == 0) throw TimeoutException('slow');
    };
    controller.start();
    await settle();
    expect(prepared, hasLength(2));
    expect(prepared.first, isNot(prepared.last));
    final queued = host.queueIds.where(isOnlineId).map((id) => online[id]!.result.id);
    expect(queued, [prepared.last]);
  });

  test('when every candidate fails nothing is queued', () async {
    prepareHook = (r) async {
      prepared.add(r.id);
      throw TimeoutException('slow');
    };
    controller.start();
    await settle();
    expect(prepared, hasLength(ShufflePlusController.prepareAttempts));
    expect(host.queueIds, library);
    expect(log.recent, isEmpty);
  });

  test('outcomes: heard to the end, skipped otherwise', () async {
    controller.start();
    await settle();
    await play(3);
    host.finishAndAdvance(toTheEnd: true); // the suggestion is current: heard
    await settle();
    await play(3);
    host.finishAndAdvance(toTheEnd: false);
    await settle();
    final outcomes = log.recent.map((r) => r.outcome).toList();
    expect(outcomes.first, SuggestionOutcome.queued, reason: 'the next one is waiting');
    expect(outcomes.last, SuggestionOutcome.heard);
    expect(log.recent.last.seedTitle, startsWith('Song'));
  });

  test('turning shuffle off takes the waiting suggestion out of the queue', () async {
    controller.start();
    await settle();
    expect(host.queueIds.where(isOnlineId), hasLength(1));
    host.shuffleEnabled = false;
    host.change();
    await settle();
    expect(host.queueIds, library);
  });

  test('a new list drops the pool: the next suggestion asks for a new radio', () async {
    controller.start();
    await settle();
    await play(5); // the first suggestion is behind us, the pool has rows
    expect(adapter.sent, hasLength(1));
    host.sourceIds = [for (var i = 1; i <= 8; i++) i];
    now = now.add(const Duration(minutes: 2));
    host.change();
    await settle();
    await play(4);
    expect(adapter.sent, hasLength(2), reason: 'rows of the old list are not reused');
  });

  test('a 429 pauses every request for 15 minutes, with a single notice', () async {
    adapter.status = 429;
    final notices = <ShufflePlusNotice>[];
    controller.notices.listen(notices.add);
    controller.start();
    await settle();
    expect(adapter.sent, hasLength(1));
    expect(notices, [ShufflePlusNotice.rateLimited]);

    now = now.add(const Duration(minutes: 14));
    controller.poke();
    await settle();
    expect(adapter.sent, hasLength(1), reason: 'still paused');

    now = now.add(const Duration(minutes: 2));
    controller.poke();
    await settle();
    expect(adapter.sent, hasLength(2));
    expect(notices, hasLength(1), reason: 'told once');
  });

  test('radio requests are at least a minute apart', () async {
    adapter.status = 500; // unreadable: falls to the (empty) yt-dlp mix
    controller.start();
    await settle();
    final first = adapter.sent.length;
    controller.poke();
    await settle();
    expect(adapter.sent.length, first);
  });

  test('three playback failures in a row stop Shuffle+ for the session', () async {
    final notices = <ShufflePlusNotice>[];
    controller.notices.listen(notices.add);
    controller.start();
    await settle();
    host
      ..fail()
      ..fail()
      ..fail();
    await settle();
    expect(notices, [ShufflePlusNotice.tooManyErrors]);
    expect(controller.stoppedForSession, isTrue);
    expect(host.queueIds, library, reason: 'the waiting suggestion is gone');
  });
}

class _NoMix implements YoutubeService {
  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async =>
      const PlaylistListing.empty();

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}
