import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:codecore/services/online/deezer_client.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/itunes_client.dart';
import 'package:codecore/services/online/lrclib_client.dart';
import 'package:codecore/services/online/wikipedia_client.dart';
import 'package:codecore/services/share/track_meta.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Fake Deezer (by ISRC) and a silent iTunes; remembers the Deezer calls.
class _Web implements WebClient {
  final urls = <String>[];

  @override
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel, bool strict = false}) async {
    urls.add(url);
    if (url.contains('/track/isrc:')) {
      return {
        'id': 1,
        'title': 'Poetica',
        'duration': 200,
        'isrc': 'ITUM71200001',
        'track_position': 4,
        'disk_number': 1,
        'artist': {'name': 'Cesare Cremonini'},
        'album': {'id': 7, 'title': 'Deezer Album'},
      };
    }
    if (url.contains('/album/')) {
      return {
        'id': 7,
        'title': 'Deezer Album',
        'record_type': 'album',
        'nb_tracks': 10,
        'release_date': '2020-05-01',
        'genres': {
          'data': [
            {'name': 'Pop'}
          ]
        },
      };
    }
    return null;
  }

  @override
  Future<List<int>?> getBytes(String url,
          {int maxBytes = 0, CancelToken? cancel}) async =>
      null;

  int get deezerCalls => urls.where((u) => u.contains('deezer')).length;
}

void main() {
  late AppDatabase db;
  late TrackRepository repo;
  late Directory tmp;
  late _Web web;
  late EnrichmentService svc;
  var deezerOn = true;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('recv_dz');
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    web = _Web();
    deezerOn = true;
    svc = EnrichmentService(
      db: db,
      tracks: repo,
      covers: CoverStore(Directory(p.join(tmp.path, 'c'))),
      itunes: ItunesClient(web),
      deezer: DeezerClient(web),
      useDeezer: () => deezerOn,
      lrclib: LrclibClient(web),
      wikipedia: WikipediaClient(web),
      web: web,
      language: () => 'it',
      limiter: RateLimiter(minGap: Duration.zero),
    );
    await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/a/x.mp3',
          title: 'file name',
          albumKey: 'old',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
        ));
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  // Same call the download enricher makes: metadata only, no lyrics.
  Future<Track> receiveAndEnrich(TrackMeta meta) async {
    final id = (await repo.byPath('/a/x.mp3'))!.id;
    await repo.applyReceivedMeta(id, meta);
    await svc.enrichMany([id], includeLyrics: false).drain<void>();
    return (await repo.getById(id))!;
  }

  test('a received userEdited track gets its empty fields from Deezer by ISRC',
      () async {
    final t = await receiveAndEnrich(const TrackMeta(
        title: 'Poetica', artist: 'Cesare Cremonini', isrc: 'ITUM71200001'));
    expect(t.userEdited, true);
    expect(t.year, 2020);
    expect(t.genre, 'Pop');
    expect(t.trackNumber, 4);
    expect(web.urls.any((u) => u.contains('/track/isrc:ITUM71200001')), true);
  });

  test('a field that came with the meta is not overwritten', () async {
    final t = await receiveAndEnrich(const TrackMeta(
        title: 'Poetica',
        artist: 'Cesare Cremonini',
        album: 'Deezer Album',
        year: 2002,
        trackNumber: 9,
        isrc: 'ITUM71200001'));
    expect(t.album, 'Deezer Album');
    expect(t.year, 2002);
    expect(t.trackNumber, 9);
    expect(t.genre, 'Pop');
  });

  test('Deezer option off: no Deezer request', () async {
    deezerOn = false;
    await receiveAndEnrich(const TrackMeta(
        title: 'Poetica', artist: 'Cesare Cremonini', isrc: 'ITUM71200001'));
    expect(web.deezerCalls, 0);
  });
}
