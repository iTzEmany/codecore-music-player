import 'dart:async';
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/import/exportify_reader.dart';
import 'package:codecore/services/import/import_candidate.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers searches from a map; records how many searches were made.
class FakeYoutube implements YoutubeService {
  final Map<String, List<YtResult>> songs = {};
  final Map<String, List<YtResult>> plain = {};
  YtException? failWith;
  int searches = 0;
  final queries = <String>[];

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    searches++;
    queries.add('songs:$query');
    if (failWith != null) throw failWith!;
    return songs.entries
        .firstWhere((e) => query.contains(e.key),
            orElse: () => const MapEntry('', []))
        .value;
  }

  @override
  Future<List<YtResult>> search(String query) async {
    searches++;
    queries.add('plain:$query');
    if (failWith != null) throw failWith!;
    return plain.entries
        .firstWhere((e) => query.contains(e.key),
            orElse: () => const MapEntry('', []))
        .value;
  }

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel,
          DownloadOptions options = const DownloadOptions()}) =>
      const Stream.empty();

  @override
  Future<String?> toolVersion() async => '2026.08.19';

  @override
  void close() {}
}

YtResult topic(String id, String title, String artist, int seconds) => YtResult(
    id: id,
    title: title,
    channel: '$artist - Topic',
    duration: Duration(seconds: seconds),
    artists: [artist]);

ImportRow row(int i, String title, String artist, int seconds) => ImportRow(
    index: i,
    title: title,
    artists: [artist],
    durationMs: seconds * 1000,
    isrc: 'ISRC$i');

void main() {
  late AppDatabase db;
  late ImportRepository imports;
  late PlaylistRepository playlists;
  late TrackRepository tracks;
  late FakeYoutube yt;
  late StreamController<DownloadItem> settled;
  late List<(YtResult, String)> queued;
  late List<String> tagged;
  late List<ImportEvent> events;
  late PlaylistImportService service;
  var cancelCalls = 0;
  final forgotten = <List<String>>[];
  var enabled = true;
  var maxInFlight = 3;

  Future<int> addTrack(String path, String title, String artist, int seconds) async {
    await tracks.upsertBatch([
      TracksCompanion.insert(
          path: path,
          title: title,
          albumKey: 'k',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          artist: Value(artist),
          durationMs: Value(seconds * 1000)),
    ]);
    return (await tracks.idForPath(path))!;
  }

  PlaylistImportService build() {
    final s = PlaylistImportService(
      imports: imports,
      playlists: playlists,
      loadLibrary: tracks.liteEntries,
      youtube: yt,
      enqueue: (r, tag) => queued.add((r, tag)),
      cancelDownloads: (_) => cancelCalls++,
      forgetSearches: forgotten.add,
      trackDurationMs: (id) async => (await tracks.getById(id))?.durationMs,
      settled: settled.stream,
      trackIdForPath: tracks.idForPath,
      pathForVideo: (_) async => null,
      applyTags: (id, r) async => tagged.add('$id:${r.title}'),
      youtubeEnabled: enabled,
      searchGap: Duration.zero,
      pollDelay: const Duration(milliseconds: 5),
      maxInFlight: maxInFlight,
    );
    s.events.listen(events.add);
    return s;
  }

  Future<void> idle() async {
    // Let the engine and the settled handlers run to quiescence.
    for (var i = 0; i < 40; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  ExportifyPlaylist csv(List<ImportRow> rows) =>
      ExportifyPlaylist(name: 'Mood', rows: rows);

  Future<List<String>> order(int playlistId) async =>
      (await playlists.watchTracks(playlistId).first).map((t) => t.title).toList();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    imports = ImportRepository(db);
    playlists = PlaylistRepository(db);
    tracks = TrackRepository(db);
    yt = FakeYoutube();
    settled = StreamController<DownloadItem>.broadcast();
    queued = [];
    tagged = [];
    events = [];
    cancelCalls = 0;
    forgotten.clear();
    enabled = true;
    maxInFlight = 3;
    service = build();
  });
  tearDown(() async {
    service.dispose();
    await settled.close();
    await db.close();
  });

  Future<void> finish(String tag, String path, {int? seconds}) async {
    // By default the file is as long as the CSV says.
    final ref = parseImportTag(tag)!;
    final want = (await imports.item(ref.$1, ref.$2))?.durationMs;
    await addTrack(
        path, path, 'x', seconds ?? (want == null ? 100 : (want / 1000).round()));
    settled.add(DownloadItem(
        id: 1,
        result: const YtResult(id: 'v', title: 't', channel: 'c', duration: null),
        status: DownloadStatus.done,
        path: path,
        tag: tag));
    await idle();
  }

  test('a track already in the library is linked without any search', () async {
    await addTrack('/m/felicita.mp3', 'Felicità', 'Lucio Dalla', 345);
    final id = await service.start(csv([row(0, 'Felicità', 'Lucio Dalla', 345)]));
    await idle();
    expect(yt.searches, 0);
    expect(queued, isEmpty);
    final imp = (await imports.get(id))!;
    expect(imp.state, ImportStatus.finished);
    expect(await order(imp.playlistId), ['Felicità']);
    expect((await imports.item(id, 0))!.state, ImportItemStatus.linked);
    expect(events.single.kind, ImportEventKind.completed);
  });

  test('a sure match is downloaded, tagged and placed in CSV order', () async {
    yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
    yt.songs['two'] = [topic('v2', 'Two', 'Band', 210)];
    final id = await service.start(
        csv([row(0, 'One', 'Band', 200), row(1, 'Two', 'Band', 210)]));
    await idle();
    expect(queued.map((q) => q.$2), [importTag(id, 0), importTag(id, 1)]);
    expect(queued.first.$1.downloadName, 'Band - One');
    expect((await imports.item(id, 0))!.state, ImportItemStatus.queued);
    expect((await imports.get(id))!.state, ImportStatus.running);

    // Second one arrives first.
    await finish(importTag(id, 1), '/m/two.mp3');
    await finish(importTag(id, 0), '/m/one.mp3');
    final imp = (await imports.get(id))!;
    expect(imp.state, ImportStatus.finished);
    expect(await order(imp.playlistId), ['/m/one.mp3', '/m/two.mp3']);
    expect(tagged, hasLength(2));
    expect((await imports.item(id, 0))!.state, ImportItemStatus.downloaded);
    expect(events.last.kind, ImportEventKind.completed);
  });

  test('an unsure match waits for the user with its candidates', () async {
    yt.songs['mother'] = [
      YtResult(
          id: 'c1',
          title: 'Pink Floyd - Mother',
          channel: 'SomeUploader',
          duration: null),
    ];
    final id = await service.start(csv([row(0, 'Mother', 'Pink Floyd', 334)]));
    await idle();
    final it = (await imports.item(id, 0))!;
    expect(it.state, ImportItemStatus.review);
    expect(decodeCandidates(it.candidates).single.id, 'c1');
    expect(queued, isEmpty);
    expect((await imports.get(id))!.state, ImportStatus.finished);

    // The user picks it: the import goes back to running.
    await service.download(id, 0, decodeCandidates(it.candidates).single.toYtResult());
    expect(queued.single.$2, importTag(id, 0));
    expect((await imports.get(id))!.state, ImportStatus.running);
    await finish(importTag(id, 0), '/m/mother.mp3');
    expect((await imports.get(id))!.state, ImportStatus.finished);
  });

  test('nothing found is saved as not found and the import goes on', () async {
    yt.songs['two'] = [topic('v2', 'Two', 'Band', 210)];
    final id = await service.start(
        csv([row(0, 'Zzz Unknown', 'Nobody', 100), row(1, 'Two', 'Band', 210)]));
    await idle();
    expect((await imports.item(id, 0))!.state, ImportItemStatus.notFound);
    expect(queued.single.$2, importTag(id, 1));
  });

  test('rate limiting pauses the import; resume continues', () async {
    yt.failWith = const YtException(YtErrorKind.rateLimited);
    final id = await service.start(csv([row(0, 'One', 'Band', 200)]));
    await idle();
    expect((await imports.get(id))!.state, ImportStatus.paused);
    expect((await imports.item(id, 0))!.state, ImportItemStatus.pending);
    expect(events.map((e) => e.kind), contains(ImportEventKind.rateLimited));

    yt.failWith = null;
    yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
    await service.resume(id);
    await idle();
    expect(queued.single.$2, importTag(id, 0));
  });

  test('cancel stops searching and drops queued downloads', () async {
    yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
    maxInFlight = 1;
    service.dispose();
    service = build();
    final id = await service.start(
        csv([row(0, 'One', 'Band', 200), row(1, 'Two', 'Band', 210)]));
    await idle();
    expect(queued, hasLength(1)); // second row waits: only one in flight
    await service.cancel(id);
    await idle();
    expect(cancelCalls, 1);
    expect((await imports.get(id))!.state, ImportStatus.cancelled);
    expect((await imports.item(id, 1))!.state, ImportItemStatus.pending);
  });

  test('no more than maxInFlight downloads wait at the same time', () async {
    const names = ['alpha', 'bravo', 'charlie', 'delta'];
    for (final n in names) {
      yt.songs[n] = [topic('v$n', n, 'Band', 100)];
    }
    maxInFlight = 2;
    service.dispose();
    service = build();
    final id = await service.start(csv([
      for (var i = 0; i < 4; i++) row(i, names[i], 'Band', 100),
    ]));
    await idle();
    expect(queued, hasLength(2));
    await finish(importTag(id, 0), '/m/alpha.mp3');
    expect(queued, hasLength(3));
  });

  test('with YouTube disabled only library tracks are linked', () async {
    enabled = false;
    service.dispose();
    service = build();
    await addTrack('/m/a.mp3', 'A', 'Band', 100);
    final id = await service.start(
        csv([row(0, 'A', 'Band', 100), row(1, 'B', 'Band', 100)]));
    await idle();
    expect(yt.searches, 0);
    expect((await imports.item(id, 0))!.state, ImportItemStatus.linked);
    expect((await imports.item(id, 1))!.state, ImportItemStatus.notFound);
  });

  test('importing the same CSV again into the playlist adds only new rows', () async {
    await addTrack('/m/a.mp3', 'A', 'Band', 100);
    final first = await service.start(csv([row(0, 'A', 'Band', 100)]));
    await idle();
    final playlistId = (await imports.get(first))!.playlistId;

    yt.songs['b'] = [topic('vb', 'B', 'Band', 100)];
    final second = await service.start(
        csv([row(0, 'A', 'Band', 100), row(1, 'B', 'Band', 100)]),
        intoPlaylistId: playlistId);
    await idle();
    final items = await imports.items(second);
    expect(items.map((i) => i.title), ['B']);
    expect(queued.single.$2, importTag(second, 1));
  });

  test('a failed download marks the row failed and can be retried', () async {
    yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
    final id = await service.start(csv([row(0, 'One', 'Band', 200)]));
    await idle();
    settled.add(DownloadItem(
        id: 1,
        result: queued.single.$1,
        status: DownloadStatus.failed,
        error: YtErrorKind.unavailable,
        tag: importTag(id, 0)));
    await idle();
    expect((await imports.item(id, 0))!.state, ImportItemStatus.failed);
    expect((await imports.get(id))!.state, ImportStatus.finished);

    await service.retry(id);
    await idle();
    expect(queued, hasLength(2));
  });

  test('a download that failed for good marks the row failed (retries live in the queue)',
      () async {
    yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
    final id = await service.start(csv([row(0, 'One', 'Band', 200)]));
    await idle();
    settled.add(DownloadItem(
        id: 1,
        result: queued.last.$1,
        status: DownloadStatus.failed,
        error: YtErrorKind.network,
        tag: importTag(id, 0)));
    await idle();
    expect(queued, hasLength(1), reason: 'the service does not re-enqueue');
    expect((await imports.item(id, 0))!.state, ImportItemStatus.failed);
  });

  group('ISRC first', () {
    test('a sure match by ISRC needs a single search', () async {
      yt.songs['ISRC0'] = [topic('v1', 'One', 'Band', 200)];
      final id = await service.start(csv([row(0, 'One', 'Band', 200)]));
      await idle();
      expect(yt.queries, ['songs:ISRC0']);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.queued);
      expect(queued.single.$1.id, 'v1');
    });

    test('a doubtful ISRC result falls back to title and artist', () async {
      // Right video but a different length: only «review» by ISRC.
      yt.songs['ISRC0'] = [topic('wrong', 'One', 'Band', 215)];
      yt.songs['band one'] = [topic('v1', 'One', 'Band', 200)];
      final id = await service.start(csv([row(0, 'One', 'Band', 200)]));
      await idle();
      expect(yt.queries.first, 'songs:ISRC0');
      expect(yt.queries[1], contains('band one'));
      expect(queued.single.$1.id, 'v1',
          reason: 'the ISRC result must not be reused');
      expect((await imports.item(id, 0))!.state, ImportItemStatus.queued);
    });

    test('a row without ISRC searches as before', () async {
      yt.songs['band one'] = [topic('v1', 'One', 'Band', 200)];
      final r = ImportRow(
          index: 0, title: 'One', artists: const ['Band'], durationMs: 200000);
      await service.start(csv([r]));
      await idle();
      expect(yt.queries, hasLength(1));
      expect(yt.queries.single, contains('band one'));
    });
  });

  test('an unavailable video makes the row forget its cached searches', () async {
    yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
    final id = await service.start(csv([row(0, 'One', 'Band', 200)]));
    await idle();
    settled.add(DownloadItem(
        id: 1,
        result: queued.last.$1,
        status: DownloadStatus.failed,
        error: YtErrorKind.unavailable,
        tag: importTag(id, 0)));
    await idle();
    expect(forgotten, hasLength(1));
    expect(forgotten.single, containsAll(['ISRC0', 'band one', 'Band - One']));
  });

  group('length check after the download', () {
    Future<int> startOne() async {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final id = await service.start(csv([row(0, 'One', 'Band', 200)]));
      await idle();
      return id;
    }

    test('a 4 s difference is fine', () async {
      final id = await startOne();
      await finish(importTag(id, 0), '/m/one.mp3', seconds: 204);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.downloaded);
    });

    test('a 40 s difference goes to review, file and playlist entry kept',
        () async {
      final id = await startOne();
      await finish(importTag(id, 0), '/m/one.mp3', seconds: 240);
      final it = (await imports.item(id, 0))!;
      expect(it.state, ImportItemStatus.review);
      expect(it.trackId, isNotNull, reason: 'the downloaded track is linked');
      final imp = (await imports.get(id))!;
      expect(await order(imp.playlistId), ['/m/one.mp3']);
    });

    test('«Tieni questo» confirms it', () async {
      final id = await startOne();
      await finish(importTag(id, 0), '/m/one.mp3', seconds: 240);
      await service.keepDownloaded(id, 0);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.downloaded);
    });

    test('a CSV row without a length is never questioned', () async {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final r = ImportRow(index: 0, title: 'One', artists: const ['Band']);
      final id = await service.start(csv([r]));
      await idle();
      await finish(importTag(id, 0), '/m/one.mp3', seconds: 999);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.downloaded);
    });
  });

  test('tag parsing', () {
    expect(parseImportTag('import:3:12'), (3, 12));
    expect(parseImportTag('other'), isNull);
    expect(parseImportTag('import:x:1'), isNull);
    expect(parseImportTag(null), isNull);
  });
}
