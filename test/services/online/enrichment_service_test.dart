import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/covers/cover_store.dart';
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

class _Web implements WebClient {
  @override
  Future<Object?> getJson(String url,
      {Map<String, String>? query, CancelToken? cancel, bool strict = false}) async {
    if (url.contains('itunes')) {
      return {
        'results': [
          {
            'trackName': 'Song',
            'artistName': 'Band',
            'collectionName': 'New Album',
            'releaseDate': '2019-01-01',
            'primaryGenreName': 'Rock',
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
}

void main() {
  late AppDatabase db;
  late TrackRepository repo;
  late Directory tmp;
  late EnrichmentService svc;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('enr');
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    final web = _Web();
    svc = EnrichmentService(
      db: db,
      tracks: repo,
      covers: CoverStore(Directory(p.join(tmp.path, 'c'))),
      itunes: ItunesClient(web),
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

  Future<Track> add(String path, String title,
      {String? album, bool edited = false, int? year}) async {
    await db.into(db.tracks).insert(TracksCompanion.insert(
          path: path,
          title: title,
          albumKey: 'k',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          artist: const Value('Band'),
          album: Value(album),
          year: Value(year),
          userEdited: Value(edited),
        ));
    return (await (db.select(db.tracks)..where((t) => t.path.equals(path)))
            .getSingle());
  }

  test('propose writes nothing', () async {
    final t = await add('/a.mp3', 'Song');
    final prop = await svc.propose(t, lyrics: false, curiosity: false);
    expect(prop.meta, isNotNull);
    final again = await repo.getById(t.id);
    expect(again!.album, isNull);
    expect(again.enrichStatus, 0);
  });

  test('apply respects userEdited', () async {
    final t = await add('/a.mp3', 'Song', album: 'Mine', edited: true);
    final prop = await svc.propose(t, lyrics: false, curiosity: false);
    await svc.apply(prop, {EnrichField.title, EnrichField.album, EnrichField.year});
    final r = (await repo.getById(t.id))!;
    expect(r.title, 'Song');
    expect(r.album, 'Mine');
    expect(r.year, 2019);
  });

  test('batch fills only empty fields and never touches title', () async {
    final t = await add('/a.mp3', 'Song', album: 'Mine', year: 1999);
    final events = await svc.enrichMany([t.id], includeLyrics: false).toList();
    expect(events.last.finished, true);
    final r = (await repo.getById(t.id))!;
    expect(r.album, 'Mine');
    expect(r.year, 1999);
    expect(r.genre, 'Rock');
    expect(r.title, 'Song');
    expect(r.hasCover, true);
  });

  test('coverForAlbum saves the album cover once and then leaves it alone',
      () async {
    final t = await add('/a.mp3', 'Song');
    expect(await svc.coverForAlbum(t, 'New Album', 'Band'), isTrue);
    expect((await repo.getById(t.id))!.hasCover, isTrue);
    expect(await svc.coverForAlbum(t, 'New Album', 'Band'), isFalse,
        reason: 'the album already has its cover');
  });

  test('coverForAlbum finds nothing for an unknown artist', () async {
    final t = await add('/b.mp3', 'Song');
    expect(await svc.coverForAlbum(t, 'New Album', 'Somebody Else'), isFalse);
    expect((await repo.getById(t.id))!.hasCover, isFalse);
  });

  test('apply on a streamed shadow row keeps its stream album key', () async {
    final t = await add('stream:youtube:x', 'Song');
    await (db.update(db.tracks)..where((r) => r.id.equals(t.id)))
        .write(const TracksCompanion(kind: Value(2), albumKey: Value('stream|youtube:x')));
    final prop = await svc.propose((await repo.getById(t.id))!, lyrics: false, curiosity: false);
    await svc.apply(prop, {EnrichField.album, EnrichField.artist});
    final r = (await repo.getById(t.id))!;
    expect(r.album, 'New Album');
    expect(r.albumKey, 'stream|youtube:x');
  });
}
