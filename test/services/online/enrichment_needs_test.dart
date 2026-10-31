import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/itunes_client.dart';
import 'package:codecore/services/online/lrclib_client.dart';
import 'package:codecore/services/online/wikipedia_client.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Counts what is asked and answers nothing.
class _Web implements WebClient {
  final asked = <String>[];

  @override
  Future<Object?> getJson(String url, {Map<String, String>? query, CancelToken? cancel, bool strict = false}) async {
    asked.add(url);
    return null;
  }

  @override
  Future<List<int>?> getBytes(String url, {int maxBytes = 0, CancelToken? cancel}) async {
    asked.add(url);
    return null;
  }
}

void main() {
  late AppDatabase db;
  late Directory tmp;
  late _Web web;
  late EnrichmentService svc;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('needs');
    db = AppDatabase(NativeDatabase.memory());
    web = _Web();
    svc = EnrichmentService(
      db: db,
      tracks: TrackRepository(db),
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

  Future<Track> add({
    bool complete = false,
    int status = 0,
    bool lyrics = false,
    String? curiosities,
  }) async {
    final id = await db.into(db.tracks).insert(TracksCompanion.insert(
          path: '/m/${DateTime.now().microsecondsSinceEpoch}.mp3',
          title: 'Song',
          albumKey: 'k',
          format: 'mp3',
          sizeBytes: 1,
          mtimeMs: 1,
          addedAt: 1,
          artist: const Value('Band'),
          album: Value(complete ? 'Album' : null),
          year: Value(complete ? 1999 : null),
          genre: Value(complete ? 'Rock' : null),
          trackNumber: Value(complete ? 3 : null),
          hasCover: Value(complete),
          lyricsPlain: Value(lyrics ? 'la la' : null),
          curiosities: Value(curiosities),
          enrichStatus: Value(status),
        ));
    return (db.select(db.tracks)..where((t) => t.id.equals(id))).getSingle();
  }

  group('needsEnrichment', () {
    test('a track with every requested field filled needs nothing', () async {
      final t = await add(complete: true, lyrics: true, status: 1);
      expect(needsEnrichment(t), isFalse);
      expect(needsEnrichment(t, curiosities: true), isTrue, reason: 'curiosities asked and missing');
    });

    test('one missing field is enough, but only among the ones asked for', () async {
      final noLyrics = await add(complete: true, status: 1);
      expect(needsEnrichment(noLyrics), isTrue);
      expect(needsEnrichment(noLyrics, lyrics: false), isFalse);
      final noMeta = await add(lyrics: true, status: 1);
      expect(needsEnrichment(noMeta), isTrue);
      expect(needsEnrichment(noMeta, metadata: false), isFalse);
    });

    test('a track for which nothing was found waits for the user', () async {
      final gaveUp = await add(status: 2);
      expect(needsEnrichment(gaveUp), isFalse);
      expect(needsEnrichment(gaveUp, force: true), isTrue, reason: '«Riprova» asks again');
    });
  });

  test('the batch does not ask the services again about complete tracks', () async {
    final done = await add(complete: true, lyrics: true, status: 1);
    final events = await svc.enrichMany([done.id]).toList();
    expect(web.asked, isEmpty);
    expect(events.last.finished, isTrue);
    expect(events.last.done, 1);
    expect(events.last.updated + events.last.notFound, 0, reason: 'skipped, not counted as looked up');
  });

  test('the batch still asks about a track that misses something', () async {
    final half = await add(lyrics: true, status: 1);
    await svc.enrichMany([half.id]).toList();
    expect(web.asked, isNotEmpty);
  });

  test('a cancelled batch leaves the tracks it did not reach as they were', () async {
    final first = await add(status: 1);
    final second = await add(status: 1);
    final cancel = CancelToken();
    await for (final _ in svc.enrichMany([first.id, second.id], cancel: cancel)) {
      cancel.cancel();
    }
    Future<int> status(Track t) async =>
        (await (db.select(db.tracks)..where((r) => r.id.equals(t.id))).getSingle()).enrichStatus;
    expect(await status(first), 1, reason: 'tried, nothing found: a status 1 stays (D-285)');
    expect(await status(second), 1, reason: 'never reached');
  });
}
