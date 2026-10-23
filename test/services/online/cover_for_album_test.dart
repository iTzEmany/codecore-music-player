import 'dart:convert';
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

Object _fx(String n) =>
    jsonDecode(File('test/fixtures/deezer/$n.json').readAsStringSync())
        as Object;

class _Web implements WebClient {
  final bytesUrls = <String>[];
  bool usableEdition = false;

  @override
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel}) async {
    if (url.contains('itunes')) {
      return {
        'results': [
          {
            'trackName': 'Imagine',
            'artistName': 'John Lennon',
            'collectionName': 'Imagine',
            'artworkUrl100': 'https://itunes/100x100bb.jpg',
          }
        ]
      };
    }
    if (usableEdition && url.contains('/track/isrc:')) {
      return {
        'id': 1,
        'title': 'Imagine',
        'duration': 183,
        'artist': {'name': 'John Lennon'},
        'album': {'id': 7, 'title': 'Imagine'},
      };
    }
    if (usableEdition && url.contains('/album/')) {
      return {
        'id': 7,
        'title': 'Imagine',
        'record_type': 'album',
        'nb_tracks': 10,
        'cover_xl': 'https://d/cover.jpg',
      };
    }
    if (url.contains('/track/isrc:')) return _fx('track_isrc_imagine_box');
    if (url.contains('/album/')) return _fx('album_signature_box');
    return null;
  }

  @override
  Future<List<int>?> getBytes(String url,
      {int maxBytes = 0, CancelToken? cancel}) async {
    bytesUrls.add(url);
    return [1, 2, 3];
  }
}

void main() {
  Future<_Web> run({required bool usable}) async {
    final tmp = Directory.systemTemp.createTempSync('cfa');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      tmp.deleteSync(recursive: true);
    });
    final web = _Web()..usableEdition = usable;
    final svc = EnrichmentService(
      db: db,
      tracks: TrackRepository(db),
      covers: CoverStore(Directory(p.join(tmp.path, 'c'))),
      itunes: ItunesClient(web),
      deezer: DeezerClient(web),
      useDeezer: () => true,
      lrclib: LrclibClient(web),
      wikipedia: WikipediaClient(web),
      web: web,
      language: () => 'it',
      limiter: RateLimiter(minGap: Duration.zero),
    );
    await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/i.mp3',
          title: 'Imagine',
          albumKey: 'k',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          artist: const Value('John Lennon'),
        ));
    final t = await db.select(db.tracks).getSingle();

    final ok = await svc.coverForAlbum(t, 'Imagine', 'John Lennon',
        isrc: 'GBAYE1000769');
    expect(ok, isTrue);
    return web;
  }

  test('Imagine: Deezer album is a box set, so the cover comes from iTunes',
      () async {
    final web = await run(usable: false);
    expect(web.bytesUrls, hasLength(1));
    expect(web.bytesUrls.single, contains('itunes'));
  });

  test('usable edition with an ISRC: the Deezer cover is used', () async {
    final web = await run(usable: true);
    expect(web.bytesUrls, ['https://d/cover.jpg']);
  });
}
