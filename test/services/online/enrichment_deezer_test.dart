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
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Answers Deezer and iTunes from memory and remembers what was asked.
class _Web implements WebClient {
  final urls = <String>[];
  bool deezerKnowsIsrc = true;
  bool deezerQuota = false;
  bool itunesGenre = true;

  @override
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel, bool strict = false}) async {
    urls.add(url);
    if (url.contains('deezer') && deezerQuota) {
      return {'error': {'code': 4, 'message': 'Quota'}};
    }
    if (url.contains('deezer') && url.contains('/track/isrc:')) {
      if (!deezerKnowsIsrc) {
        return {'error': {'code': 800, 'message': 'no data'}};
      }
      return {
        'id': 1,
        'title': 'Song',
        'duration': 200,
        'isrc': 'ITABC2400001',
        'track_position': 4,
        'disk_number': 2,
        'artist': {'name': 'Band'},
        'album': {'id': 7, 'title': 'Deezer Album'},
      };
    }
    if (url.contains('deezer') && url.contains('/album/')) {
      return {
        'id': 7,
        'title': 'Deezer Album',
        'record_type': 'album',
        'nb_tracks': 10,
        'release_date': '2020-05-01',
        'cover_xl': 'https://d/cover.jpg',
        'genres': {
          'data': [
            {'name': 'Pop'}
          ]
        },
      };
    }
    if (url.contains('itunes')) {
      return {
        'results': [
          {
            'trackName': 'Song',
            'artistName': 'Band',
            'collectionName': 'iTunes Album',
            'releaseDate': '2019-01-01',
            if (itunesGenre) 'primaryGenreName': 'Rock',
            'trackNumber': 2,
            'artworkUrl100': 'https://x/100x100bb.jpg',
          }
        ]
      };
    }
    return null;
  }

  @override
  Future<List<int>?> getBytes(String url,
          {int maxBytes = 0, CancelToken? cancel}) async =>
      [1, 2, 3];

  int count(String part) => urls.where((u) => u.contains(part)).length;
}

void main() {
  late AppDatabase db;
  late TrackRepository repo;
  late Directory tmp;
  late _Web web;
  late EnrichmentService svc;
  var deezerOn = true;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('enrdz');
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
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<Track> add({bool edited = false}) async {
    await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/a.mp3',
          title: 'Song',
          albumKey: 'k',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          durationMs: const Value(200000),
          artist: const Value('Band'),
          isrc: const Value('ITABC2400001'),
          userEdited: Value(edited),
        ));
    return (await db.select(db.tracks).getSingle());
  }

  Future<EnrichmentProposal> propose(Track t, {bool needGenre = true}) =>
      svc.propose(t, lyrics: false, curiosity: false, needGenre: needGenre);

  test('Deezer confirms with a cover and no genre is wanted: iTunes is not asked',
      () async {
    final prop = await propose(await add(), needGenre: false);
    expect(web.count('itunes'), 0);
    expect(prop.source, 'deezer');
    expect(prop.meta!.album, 'Deezer Album');
    expect(prop.disc, 2);
    expect(prop.isrc, 'ITABC2400001');
    expect(prop.coverUrl, 'https://d/cover.jpg');
  });

  test('Deezer confirmed with a cover: the iTunes genre wins, Deezer is the fallback',
      () async {
    final prop = await propose(await add());
    expect(prop.source, 'deezer+itunes');
    expect(prop.meta!.genre, 'Rock');
    expect(prop.coverUrl, 'https://d/cover.jpg');
    expect(web.count('deezer'), 2);
    web.itunesGenre = false;
    final again = await propose((await db.select(db.tracks).getSingle()));
    expect(again.meta!.genre, 'Pop');
  });

  test('Deezer resting: no Deezer request, iTunes is used', () async {
    web.deezerQuota = true;
    final t = await add();
    await propose(t); // trips the quota
    final before = web.count('deezer');
    final prop = await propose(t);
    expect(web.count('deezer'), before);
    expect(prop.source, 'itunes');
  });

  test('Deezer does not confirm: iTunes as today', () async {
    web.deezerKnowsIsrc = false;
    final prop = await propose(await add());
    expect(web.count('itunes'), 1);
    expect(prop.source, 'itunes');
    expect(prop.meta!.album, 'iTunes Album');
    expect(prop.disc, isNull);
  });

  test('option off: no Deezer request', () async {
    deezerOn = false;
    await propose(await add());
    expect(web.count('deezer'), 0);
    expect(web.count('itunes'), 1);
  });

  test("apply writes disc and ISRC, but userEdited keeps the album", () async {
    final t = await add(edited: true);
    final prop = await propose(t);
    await svc.apply(prop, {
      EnrichField.album,
      EnrichField.year,
      EnrichField.trackNumber,
    });
    final r = (await repo.getById(t.id))!;
    expect(r.album, isNull);
    expect(r.year, 2020);
    expect(r.trackNumber, 4);
    expect(r.discNumber, 2);
    expect(r.isrc, 'ITABC2400001');
  });
}
