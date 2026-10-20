import 'dart:async';
import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/data/repositories/playlist_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/import/import_candidate.dart';
import 'package:codecore/services/import/import_options.dart';
import 'package:codecore/services/import/imported_playlist.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:codecore/services/import/track_matcher.dart' show MatchThresholds;
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
  final Map<String, List<YtResult>> albums = {};
  final Map<String, List<YtResult>> soundcloud = {};
  int albumSearches = 0, albumPages = 0, scSearches = 0;
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
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async =>
      const PlaylistListing.empty();

  @override
  Future<List<YtResult>> searchSoundCloud(String query, {int limit = 5}) async {
    scSearches++;
    queries.add('sc:$query');
    return soundcloud.entries
        .firstWhere((e) => query.contains(e.key),
            orElse: () => const MapEntry('', []))
        .value;
  }

  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async {
    albumSearches++;
    queries.add('albums:$query');
    if (failWith != null) throw failWith!;
    return [
      for (final k in albums.keys)
        if (query.toLowerCase().contains(k))
          YtResult(id: 'link:$k', title: k, channel: '', duration: null),
    ];
  }

  @override
  Future<List<YtResult>> albumTracks(String albumLink) async {
    albumPages++;
    return albums[albumLink.substring(5)] ?? const [];
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
  final coverCalls = <String>[];
  var coverFails = false;
  final forgotten = <List<String>>[];
  var enabled = true;
  var scFallback = false;
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
      fetchCover: (id, row) async {
        coverCalls.add('$id:${row.album}');
        if (coverFails) throw StateError('iTunes down');
      },
      youtubeEnabled: enabled,
      soundCloudFallback: () => scFallback,
      searchGap: Duration.zero,
      pollDelay: Duration.zero,
      maxInFlight: maxInFlight,
    );
    s.events.listen(events.add);
    return s;
  }

  /// Lets the engine and the settled handlers run to quiescence. Every timer
  /// on their path is zero-length (searchGap, pollDelay, drift's Timer.run on
  /// an in-memory database), so a fixed number of event-loop turns is enough:
  /// no wall-clock wait, and the same interleaving on any machine.
  Future<void> idle() async {
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  ImportedPlaylist csv(List<ImportRow> rows) =>
      ImportedPlaylist(name: 'Mood', rows: rows);

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
    coverCalls.clear();
    coverFails = false;
    forgotten.clear();
    enabled = true;
    scFallback = false;
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
    expect(queued.first.$1.subdir, isNull, reason: 'no folder option');
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

  group('SoundCloud as a last resort', () {
    YtResult scTrack(String id, String title, String uploader, int seconds) => YtResult(
          id: id,
          title: title,
          channel: uploader,
          duration: Duration(seconds: seconds),
          source: MediaSource.soundcloud,
          webpageUrl: 'https://soundcloud.com/$uploader/$id',
        );

    test('off (the default): a row nobody else finds stays not found and SoundCloud is never asked', () async {
      yt.soundcloud['rare'] = [scTrack('s1', 'Rare Song', 'Band', 200)];
      final id = await service.start(csv([row(0, 'Rare Song', 'Band', 200)]));
      await idle();
      expect(yt.scSearches, 0);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.notFound);
      expect(queued, isEmpty);
    });

    test('on: one SoundCloud search for the row, and a sure match is downloaded from its page', () async {
      scFallback = true;
      yt.soundcloud['rare'] = [scTrack('s1', 'Rare Song', 'Band', 200)];
      final id = await service.start(csv([row(0, 'Rare Song', 'Band', 200)]));
      await idle();
      expect(yt.scSearches, 1);
      expect(queued, hasLength(1));
      final r = queued.single.$1;
      expect(r.source, MediaSource.soundcloud);
      expect(r.downloadUrl, 'https://soundcloud.com/Band/s1');
      expect((await imports.item(id, 0))!.state, ImportItemStatus.queued);
    });

    test('on: a row YouTube finds never reaches SoundCloud', () async {
      scFallback = true;
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      yt.soundcloud['one'] = [scTrack('s1', 'One', 'Band', 200)];
      await service.start(csv([row(0, 'One', 'Band', 200)]));
      await idle();
      expect(yt.scSearches, 0);
      expect(queued.single.$1.source, MediaSource.youtube);
    });

    test('on: nothing on SoundCloud either is still just «not found», after exactly one search', () async {
      scFallback = true;
      final id = await service.start(csv([row(0, 'Zzz Unknown', 'Nobody', 100)]));
      await idle();
      expect(yt.scSearches, 1);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.notFound);
    });

    test('on: an unsure SoundCloud match waits for the user and keeps its source and page', () async {
      scFallback = true;
      // A third party with the artist only in the title and a length 6 s off:
      // plausible, not sure.
      yt.soundcloud['rare'] = [scTrack('s2', 'Band - Rare Song', 'dj', 206)];
      final id = await service.start(csv([row(0, 'Rare Song', 'Band', 200)]));
      await idle();
      final it = (await imports.item(id, 0))!;
      expect(it.state, ImportItemStatus.review);
      final c = decodeCandidates(it.candidates).single;
      expect(c.source, MediaSource.soundcloud);
      expect(c.webpageUrl, 'https://soundcloud.com/dj/s2');
      expect(c.toYtResult().downloadUrl, c.webpageUrl);
    });

    test('a candidate saved before sources existed reads back as YouTube', () {
      final c = decodeCandidates('[{"id":"abc","title":"T","channel":"C","durationSec":10,"score":0.9}]').single;
      expect(c.source, MediaSource.youtube);
      expect(c.webpageUrl, isNull);
      expect(c.toYtResult().downloadUrl, 'https://www.youtube.com/watch?v=abc');
    });
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

  group('a pasted YouTube playlist (startFromResults)', () {
    YtResult video(String id, String title, String channel, int seconds) => YtResult(
          id: id,
          title: title,
          channel: channel,
          duration: Duration(seconds: seconds),
        );

    test('every video is downloaded as listed, in order, with no search at all', () async {
      final id = await service.startFromResults('My mix', [
        video('a1', 'Daft Punk - One More Time', 'Daft Punk', 320),
        video('b2', 'Some Talk - Computerphile', 'Computerphile', 900),
        video('c3', 'Third', 'Chan', 100),
      ]);
      await idle();

      expect(yt.searches, 0, reason: 'nothing is searched: the videos are known');
      expect(yt.albumSearches, 0);
      expect(queued.map((q) => q.$2), [importTag(id, 0), importTag(id, 1), importTag(id, 2)]);
      expect(queued.map((q) => q.$1.id), ['a1', 'b2', 'c3']);
      expect(queued.first.$1.downloadUrl, 'https://www.youtube.com/watch?v=a1');
      expect(queued.first.$1.downloadName, 'Daft Punk - One More Time', reason: 'the title read as «Artist - Title»');
      final imp = (await imports.get(id))!;
      expect(imp.sourceName, 'My mix');
      expect(imp.sourceKind, 'youtube');
      expect((await imports.item(id, 2))!.state, ImportItemStatus.queued);
    });

    test('a video already in the library is linked, not downloaded again', () async {
      await addTrack('/m/one.mp3', 'One More Time', 'Daft Punk', 320);
      final id = await service.startFromResults('Mix', [
        video('a1', 'Daft Punk - One More Time', 'Daft Punk', 320),
        video('b2', 'Other', 'Chan', 100),
      ]);
      await idle();
      expect(queued.map((q) => q.$1.id), ['b2']);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.linked);
    });

    test('an empty list finishes at once and an unnamed one is called YouTube', () async {
      final id = await service.startFromResults('  ', const []);
      expect((await imports.get(id))!.state, ImportStatus.finished);
      expect((await imports.get(id))!.sourceName, 'YouTube');
    });

    test('rowFromResult: channel as artist when the title does not say, credited artists first', () {
      final plain = PlaylistImportService.rowFromResult(3, video('x', 'Just A Title', 'Some Channel', 60));
      expect(plain.title, 'Just A Title');
      expect(plain.artists, ['Some Channel']);
      expect(plain.index, 3);
      final topicChannel = PlaylistImportService.rowFromResult(0, video('x', 'Song', 'Band - Topic', 60));
      expect(topicChannel.artists, ['Band']);
      final credited = PlaylistImportService.rowFromResult(
          0, const YtResult(id: 'x', title: 'Song', channel: 'c', duration: null, artists: ['A', 'B']));
      expect(credited.artists, ['A', 'B']);
      final none = PlaylistImportService.rowFromResult(0, video('x', 'Song', '', 60));
      expect(none.artists, isEmpty);
    });
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

  test('a failed download marks the row failed, an unavailable video forgets '
      'its cached searches, and the row can be retried', () async {
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
    expect(queued, hasLength(1),
        reason: 'the service does not re-enqueue: retries live in the queue');
    expect(forgotten.single, containsAll(['ISRC0', 'band one', 'Band - One']));

    await service.retry(id);
    await idle();
    expect(queued, hasLength(2));
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

    test('a 40 s difference goes to review with a note, file and playlist '
        'entry kept; «Tieni questo» confirms it', () async {
      final id = await startOne();
      await finish(importTag(id, 0), '/m/one.mp3', seconds: 240);
      final it = (await imports.item(id, 0))!;
      expect(it.state, ImportItemStatus.review);
      expect(it.note, ImportNote.lengthOff);
      expect(it.trackId, isNotNull, reason: 'the downloaded track is linked');
      final imp = (await imports.get(id))!;
      expect(await order(imp.playlistId), ['/m/one.mp3']);

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

  group('link only', () {
    test('links what the library has and never calls YouTube', () async {
      await addTrack('/m/felicita.mp3', 'Felicità', 'Lucio Dalla', 345);
      final id = await service.start(
          csv([row(0, 'Felicità', 'Lucio Dalla', 345), row(1, 'One', 'Band', 200)]),
          options: const ImportOptions(linkOnly: true));
      await idle();
      expect(yt.searches, 0);
      expect(queued, isEmpty);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.linked);
      final other = (await imports.item(id, 1))!;
      expect(other.state, ImportItemStatus.notFound);
      expect(other.note, ImportNote.linkOnly);
      expect((await imports.get(id))!.state, ImportStatus.finished);
      expect((await imports.get(id))!.linkOnly, isTrue);
    });
  });

  group('review before downloading', () {
    setUp(() {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      yt.songs['two'] = [
        topic('v2', 'Two', 'Band', 210),
        topic('v2b', 'Two (alt)', 'Band', 211),
      ];
    });

    Future<int> plan() async {
      final id = await service.start(
          csv([row(0, 'One', 'Band', 200), row(1, 'Two', 'Band', 210)]),
          options: const ImportOptions(planFirst: true));
      await idle();
      return id;
    }

    test('searches everything, downloads nothing and waits', () async {
      final id = await plan();
      expect(queued, isEmpty);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.planned);
      expect((await imports.item(id, 1))!.state, ImportItemStatus.planned);
      expect((await imports.item(id, 0))!.videoId, 'v1');
      expect(decodeCandidates((await imports.item(id, 1))!.candidates), isNotEmpty);
      expect((await imports.get(id))!.state, ImportStatus.paused);
      expect(events.map((e) => e.kind), contains(ImportEventKind.planned));
    });

    test('«Scarica» sends the plan through the normal engine and the import '
        'then finishes as usual', () async {
      final id = await plan();
      expect(await service.startPlanned(id), 2);
      await idle();
      expect(queued.map((q) => q.$1.id), ['v1', 'v2']);
      expect((await imports.item(id, 0))!.state, ImportItemStatus.queued);
      expect((await imports.get(id))!.state, ImportStatus.running);
      expect(yt.queries.where((q) => q.startsWith('songs:band')).length, 2,
          reason: 'no new searches for the approved rows');

      await finish(importTag(id, 0), '/m/one.mp3');
      await finish(importTag(id, 1), '/m/two.mp3');
      expect((await imports.get(id))!.state, ImportStatus.finished);
    });

    test('another candidate can be chosen first; a skipped row is not downloaded',
        () async {
      final id = await plan();
      final alt = decodeCandidates((await imports.item(id, 1))!.candidates)
          .firstWhere((c) => c.id == 'v2b');
      await service.choosePlanned(id, 1, alt);
      await service.skip(id, 0);
      expect(await service.startPlanned(id), 1);
      await idle();
      expect(queued.map((q) => q.$1.id), ['v2b']);
    });

  });

  group('thresholds from the settings', () {
    test('a stricter «sure» sends the same match to review', () async {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final strict = PlaylistImportService(
        imports: imports,
        playlists: playlists,
        loadLibrary: tracks.liteEntries,
        youtube: yt,
        enqueue: (r, tag) => queued.add((r, tag)),
        cancelDownloads: (_) {},
        settled: settled.stream,
        trackIdForPath: tracks.idForPath,
        pathForVideo: (_) async => null,
        applyTags: (id, r) async {},
        searchGap: Duration.zero,
        thresholds: () => const MatchThresholds(sure: 1.01, review: 0.5),
      );
      addTearDown(strict.dispose);
      final id = await strict.start(csv([row(0, 'One', 'Band', 200)]));
      await idle();
      expect((await imports.item(id, 0))!.state, ImportItemStatus.review);
      expect(queued, isEmpty);
    });
  });

  group('big files in blocks', () {
    ImportedPlaylist rows250() => csv([
          for (var i = 0; i < 250; i++) row(i, 'Song $i', 'Band', 200),
        ]);

    test('250 rows become 3 imports with their row numbers kept', () async {
      final first = await service.start(rows250(),
          options: const ImportOptions(linkOnly: true), blockSize: 100);
      await idle();
      final all = await imports.forPlaylist((await imports.get(first))!.playlistId);
      expect(all, hasLength(3));
      expect(all.map((i) => i.sourceName), ['Mood (1/3)', 'Mood (2/3)', 'Mood (3/3)']);
      expect([for (final i in all) (await imports.items(i.id)).length], [100, 100, 50]);
      expect((await imports.items(all[1].id)).first.rowIndex, 100);
      expect((await imports.items(all[2].id)).last.rowIndex, 249);
    });

    test('the blocks run one after the other', () async {
      final small = csv([
        for (var i = 0; i < 30; i++) row(i, 'Song $i', 'Band', 200),
      ]);
      final first = await service.start(small,
          options: const ImportOptions(linkOnly: true), blockSize: 10);
      final pl = (await imports.get(first))!.playlistId;
      final right = await imports.forPlaylist(pl);
      expect(right[1].state, ImportStatus.paused,
          reason: 'waits for the block before it');
      expect(right[2].state, ImportStatus.paused);
      var done = await imports.forPlaylist(pl);
      for (var i = 0;
          i < 20 && !done.every((x) => x.state == ImportStatus.finished);
          i++) {
        await idle();
        done = await imports.forPlaylist(pl);
      }
      expect(done.every((i) => i.state == ImportStatus.finished), isTrue,
          reason: '${done.map((i) => i.state)}');
    });

    test('a small file is a single import', () async {
      final first = await service.start(csv([row(0, 'One', 'Band', 200)]),
          options: const ImportOptions(linkOnly: true), blockSize: 100);
      await idle();
      final all = await imports.forPlaylist((await imports.get(first))!.playlistId);
      expect(all, hasLength(1));
      expect(all.single.sourceName, 'Mood');
    });

    test('cancelling a block leaves the next ones waiting, not started', () async {
      final first = await service.start(rows250(),
          options: const ImportOptions(planFirst: true), blockSize: 100);
      await service.cancel(first);
      await idle();
      final all = await imports.forPlaylist((await imports.get(first))!.playlistId);
      expect(all[0].state, ImportStatus.cancelled);
      expect(all[1].state, ImportStatus.paused);
    });
  });

  group('folder and numbered file names', () {
    ImportRow nth(int i) =>
        ImportRow(index: i, title: 'Song', artists: const ['Band']);

    test('importDownloadName: width follows the total, at least two digits', () {
      expect(importDownloadName(nth(6), number: true, total: 34), '07 - Band - Song');
      expect(importDownloadName(nth(6), number: true, total: 120), '007 - Band - Song');
      expect(importDownloadName(nth(0), number: true, total: 5), '01 - Band - Song');
      expect(importDownloadName(nth(6), number: false, total: 120), 'Band - Song');
    });

    test('the queued download carries the number and the folder', () async {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final rows = [row(0, 'One', 'Band', 200)];
      final id = await service.start(csv(rows),
          options: const ImportOptions(numberFiles: true, folderPath: 'Mood'));
      await idle();
      expect(queued.single.$1.downloadName, '01 - Band - One');
      expect(queued.single.$1.subdir, 'Mood');
      expect((await imports.get(id))!.folderPath, 'Mood');
    });

    test('blocks share one number width, sized on the whole playlist', () async {
      yt.songs['song'] = [topic('v', 'Song 0', 'Band', 200)];
      final first = await service.start(
          csv([for (var i = 0; i < 120; i++) row(i, 'Song $i', 'Band', 200)]),
          options: const ImportOptions(numberFiles: true, planFirst: true),
          blockSize: 40);
      await service.cancel(first);
      expect(await imports.maxRowIndexForPlaylist(
              (await imports.get(first))!.playlistId),
          119);
    });
  });

  group('covers and notes', () {
    ImportRow withAlbum(int i, String album) => ImportRow(
        index: i,
        title: 'One',
        artists: const ['Band'],
        album: album,
        durationMs: 200000,
        isrc: 'ISRC$i');

    test('«Cerca le copertine» looks the album cover up after the download',
        () async {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final id = await service.start(csv([withAlbum(0, 'Mood')]),
          options: const ImportOptions(fetchCovers: true));
      await idle();
      await finish(importTag(id, 0), '/m/one.mp3');
      expect(coverCalls, hasLength(1));
      expect(coverCalls.single, endsWith(':Mood'));
      expect((await imports.item(id, 0))!.state, ImportItemStatus.downloaded);
    });

    test('with the option off no cover is requested', () async {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final id = await service.start(csv([withAlbum(0, 'Mood')]));
      await idle();
      await finish(importTag(id, 0), '/m/one.mp3');
      expect(coverCalls, isEmpty);
    });

    test('a row without an album asks for nothing', () async {
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final id = await service.start(csv([row(0, 'One', 'Band', 200)]),
          options: const ImportOptions(fetchCovers: true));
      await idle();
      await finish(importTag(id, 0), '/m/one.mp3');
      expect(coverCalls, isEmpty);
    });

    test('a failing cover lookup never fails the import', () async {
      coverFails = true;
      yt.songs['one'] = [topic('v1', 'One', 'Band', 200)];
      final id = await service.start(csv([withAlbum(0, 'Mood')]),
          options: const ImportOptions(fetchCovers: true));
      await idle();
      await finish(importTag(id, 0), '/m/one.mp3');
      expect((await imports.item(id, 0))!.state, ImportItemStatus.downloaded);
      expect((await imports.get(id))!.state, ImportStatus.finished);
    });

    test('rows that did not make it say why', () async {
      yt.songs['one'] = [topic('v1', 'Another', 'Other', 90)];
      final id = await service.start(csv([
        row(0, 'One', 'Band', 200),
        row(1, 'Gone', 'Band', 200),
      ]));
      await idle();
      expect((await imports.item(id, 0))!.note, isIn([ImportNote.noResults, ImportNote.lowScore]));
      settled.add(DownloadItem(
          id: 1,
          result: const YtResult(id: 'x', title: 't', channel: 'c', duration: null),
          status: DownloadStatus.failed,
          error: YtErrorKind.network,
          tag: importTag(id, 1)));
      await idle();
      expect((await imports.item(id, 1))!.note, ImportNote.downloadFailed);
    });
  });

  group('sync from a refreshed file', () {
    late int pid;

    /// The ISRC belongs to the song, not to its row.
    ImportRow song(int i, String title) => ImportRow(
        index: i,
        title: title,
        artists: const ['Band'],
        durationMs: 200000,
        isrc: 'I-$title');

    /// A..E in the library, imported (all linked), plus a track X added by hand
    /// right after B.
    Future<void> setUpPlaylist() async {
      for (final t in ['A', 'B', 'C', 'D', 'E']) {
        await addTrack('/m/$t.mp3', t, 'Band', 200);
      }
      final first = await service.start(csv([
        for (var i = 0; i < 5; i++) song(i, 'ABCDE'[i]),
      ]));
      await idle();
      pid = (await imports.get(first))!.playlistId;
      final x = await addTrack('/m/X.mp3', 'X', 'Other', 100);
      await playlists.addTracks(pid, [x]);
      await playlists.reorder(pid, 5, 2);
      expect(await order(pid), ['A', 'B', 'X', 'C', 'D', 'E']);
    }

    test('adds the new, removes the gone, follows the new order, keeps the hand-made',
        () async {
      await setUpPlaylist();
      yt.songs['band f'] = [topic('vf', 'F', 'Band', 200)];
      final fresh = csv([
        song(0, 'C'),
        song(1, 'A'),
        song(2, 'F'),
        song(3, 'E'),
      ]);
      final diff = await service.previewSync(fresh, pid);
      expect(diff.added.map((r) => r.title), ['F']);
      expect(diff.removed.map((o) => o.title), ['B', 'D']);

      final id = await service.sync(fresh, pid);
      await idle();
      expect(queued.single.$1.id, 'vf', reason: 'only the new row is searched');
      await finish(importTag(id, 2), '/m/F.mp3');
      expect(await order(pid), ['C', 'A', 'X', '/m/F.mp3', 'E']);
      expect((await imports.get(id))!.state, ImportStatus.finished);
    });

    test('removed songs leave only the playlist, never the library', () async {
      await setUpPlaylist();
      final id = await service.sync(
          csv([song(0, 'A'), song(1, 'C')]), pid);
      await idle();
      expect(await order(pid), ['A', 'X', 'C']);
      expect(await tracks.countAll(), 6, reason: 'B, D and E are still in the library');
      final old = await imports.forPlaylist(pid);
      final oldItems = await imports.items(old.first.id);
      expect(oldItems.where((i) => i.state == ImportItemStatus.removed),
          hasLength(3), reason: 'B, D, E are marked «removed from the source»');
      expect((await imports.get(id))!.state, ImportStatus.finished);
    });

    test('the same file again changes nothing', () async {
      await setUpPlaylist();
      final before = await order(pid);
      final id = await service.sync(
          csv([for (var i = 0; i < 5; i++) song(i, 'ABCDE'[i])]), pid);
      await idle();
      expect(await order(pid), before);
      expect(queued, isEmpty);
      final items = await imports.items(id);
      expect(items.every((i) => i.note == ImportNote.unchanged), isTrue);
      expect((await imports.get(id))!.state, ImportStatus.finished);
    });

    test('a second sync works from the first one', () async {
      await setUpPlaylist();
      await service.sync(
          csv([song(0, 'B'), song(1, 'A')]), pid);
      await idle();
      // X was after B and goes with it.
      expect(await order(pid), ['B', 'X', 'A']);
      final diff = await service.previewSync(
          csv([song(0, 'A')]), pid);
      expect(diff.removed.map((o) => o.title), ['B']);
      expect(diff.kept, hasLength(1));
    });
  });

  group('whole albums', () {
    ImportRow inAlbum(int i, String title, String album) => ImportRow(
        index: i,
        title: title,
        artists: const ['Band'],
        album: album,
        durationMs: 200000);

    YtResult albumTrack(String id, String title, String album) => YtResult(
        id: id,
        title: title,
        channel: 'Band - Topic',
        duration: const Duration(seconds: 200),
        artists: const ['Band'],
        album: album);

    test('4 songs of one album: one album search, one page, no single searches',
        () async {
      yt.albums['mood'] = [
        for (var i = 0; i < 4; i++) albumTrack('a$i', 'Song $i', 'Mood'),
      ];
      maxInFlight = 10;
      service = build();
      final id = await service.start(csv([
        for (var i = 0; i < 4; i++) inAlbum(i, 'Song $i', 'Mood'),
      ]));
      await idle();
      expect(yt.albumSearches, 1);
      expect(yt.albumPages, 1);
      expect(yt.queries.where((q) => !q.startsWith('albums:')), isEmpty);
      expect(queued.map((q) => q.$1.id), ['a0', 'a1', 'a2', 'a3']);
      expect((await imports.item(id, 2))!.state, ImportItemStatus.queued);
    });

    test('a sure match by ISRC comes before the album page', () async {
      for (var i = 0; i < 3; i++) {
        yt.songs['ISRC$i'] = [topic('i$i', 'Song $i', 'Band', 200)];
      }
      yt.albums['mood'] = [
        for (var i = 0; i < 3; i++) albumTrack('a$i', 'Song $i', 'Mood'),
      ];
      maxInFlight = 10;
      service = build();
      await service.start(csv([
        for (var i = 0; i < 3; i++)
          ImportRow(
              index: i,
              title: 'Song $i',
              artists: const ['Band'],
              album: 'Mood',
              durationMs: 200000,
              isrc: 'ISRC$i'),
      ]));
      await idle();
      expect(yt.albumSearches, 0);
      expect(yt.queries, ['songs:ISRC0', 'songs:ISRC1', 'songs:ISRC2']);
      expect(queued.map((q) => q.$1.id), ['i0', 'i1', 'i2']);
    });

    test('fewer than 3 songs in the album: the usual single searches', () async {
      yt.albums['mood'] = [albumTrack('a0', 'Song 0', 'Mood')];
      yt.songs['song'] = [topic('s', 'Song 0', 'Band', 200)];
      await service.start(csv([
        inAlbum(0, 'Song 0', 'Mood'),
        inAlbum(1, 'Song 1', 'Mood'),
      ]));
      await idle();
      expect(yt.albumSearches, 0);
    });

    test('a song missing from the album page falls back to its own search',
        () async {
      yt.albums['mood'] = [
        albumTrack('a0', 'Song 0', 'Mood'),
        albumTrack('a1', 'Song 1', 'Mood'),
      ];
      yt.songs['song 2'] = [topic('solo', 'Song 2', 'Band', 200)];
      await service.start(csv([
        for (var i = 0; i < 3; i++) inAlbum(i, 'Song $i', 'Mood'),
      ]));
      await idle();
      expect(yt.albumSearches, 1);
      expect(queued.map((q) => q.$1.id), ['a0', 'a1', 'solo']);
    });

    test('the album found must be the one in the file', () async {
      yt.albums['mood'] = [
        for (var i = 0; i < 3; i++) albumTrack('x$i', 'Song $i', 'Greatest Hits'),
      ];
      yt.songs['song'] = [topic('s', 'Song 0', 'Band', 200)];
      await service.start(csv([
        for (var i = 0; i < 3; i++) inAlbum(i, 'Song $i', 'Mood'),
      ]));
      await idle();
      expect(queued.map((q) => q.$1.id), isNot(contains('x0')));
    });
  });

  test('tag parsing', () {
    expect(parseImportTag('import:3:12'), (3, 12));
    expect(parseImportTag('other'), isNull);
    expect(parseImportTag('import:x:1'), isNull);
    expect(parseImportTag(null), isNull);
  });
}
