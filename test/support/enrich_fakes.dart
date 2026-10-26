import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/artist_info_repository.dart';
import 'package:codecore/data/repositories/credits_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/covers/cover_store.dart';
import 'package:codecore/services/online/credits.dart';
import 'package:codecore/services/online/curiosity_finder.dart';
import 'package:codecore/services/online/curiosity_service.dart';
import 'package:codecore/services/online/deezer_client.dart';
import 'package:codecore/services/online/deezer_gw_client.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:codecore/services/online/http_client.dart';
import 'package:codecore/services/online/itunes_client.dart';
import 'package:codecore/services/online/lrclib_client.dart';
import 'package:codecore/services/online/lyrics_chain.dart';
import 'package:codecore/services/online/musicbrainz_client.dart';
import 'package:codecore/services/online/wikipedia_client.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

enum ItunesMode { match, empty, down }

/// iTunes, Deezer and MusicBrainz from memory; counts what was asked.
class EnrichWeb implements WebClient {
  ItunesMode itunes = ItunesMode.match;
  bool deezerDown = false;
  final urls = <String>[];
  int bytes = 0;

  int count(String part) => urls.where((u) => u.contains(part)).length;

  @override
  Future<Object?> getJson(
    String url, {
    Map<String, String>? query,
    CancelToken? cancel,
    bool strict = false,
  }) async {
    urls.add(url);
    if (deezerDown && url.contains('deezer')) return null;
    if (url.contains('itunes')) {
      if (itunes == ItunesMode.down) {
        if (strict) throw WebUnavailableException(url, 503);
        return null;
      }
      if (itunes == ItunesMode.empty) return {'results': <Object>[]};
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
          },
        ],
      };
    }
    if (url.contains('/track/isrc:')) {
      return {
        'id': 1,
        'title': 'Song',
        'duration': 200,
        'isrc': 'ITABC2400001',
        'artist': {'name': 'Band'},
        'album': {'id': 7, 'title': 'Deezer Album'},
      };
    }
    if (url.endsWith('/track/1')) {
      return {
        'bpm': 120.0,
        'rank': 5,
        'explicit_lyrics': false,
        'album': {'id': 7},
      };
    }
    if (url.contains('deezer') && url.contains('/album/')) {
      return {
        'id': 7,
        'title': 'Deezer Album',
        'label': 'Big Label',
        'fans': 9,
        'record_type': 'album',
        'release_date': '2020-05-01',
      };
    }
    if (url.contains('musicbrainz.org/ws/2/isrc/')) {
      return {
        'recordings': [
          {
            'id': 'mbid-1',
            'title': 'Song',
            'length': 200000,
            'artist-credit': [
              {
                'artist': {'id': 'a1', 'name': 'Band'},
              },
            ],
          },
        ],
      };
    }
    if (url.contains('musicbrainz.org/ws/2/recording/')) {
      return {
        'id': 'mbid-1',
        'relations': [
          {
            'target-type': 'artist',
            'type': 'producer',
            'attributes': <String>[],
            'artist': {'id': 'a2', 'name': 'Pro Ducer'},
          },
        ],
      };
    }
    return null;
  }

  @override
  Future<List<int>?> getBytes(
    String url, {
    int maxBytes = 0,
    CancelToken? cancel,
  }) async {
    bytes++;
    return [1, 2, 3];
  }
}

class FakeGw extends DeezerGwClient {
  @override
  Future<void> load() async {}

  @override
  bool get isPaused => false;

  @override
  Future<DeezerContributors> pageTrack(int sngId) async =>
      DeezerContributors([TrackCredit('Wri Ter', 'composer', 'deezer')]);
}

/// The lyrics chain: counts the searches and gives [result] (or [failed]).
class FakeChain extends LyricsChain {
  FakeChain(WebClient web) : super(lrclib: LrclibClient(web));

  int calls = 0;
  LyricsResult? result = const LyricsResult(
    plain: 'la la',
    synced: '[00:01.00]la la',
  );
  bool failed = false;
  bool syncedFailed = false;
  bool? wantSyncedSeen;

  /// Runs while the search is «on the network», before it answers.
  Future<void> Function()? during;

  @override
  Future<LyricsChainResult> find(
    Track t, {
    bool wantSynced = true,
    CancelToken? cancel,
  }) async {
    calls++;
    wantSyncedSeen = wantSynced;
    await during?.call();
    return failed
        ? const LyricsChainResult(failed: true, syncedFailed: true)
        : LyricsChainResult(
            lyrics: result,
            syncedFailed: syncedFailed,
            source: 'fake',
          );
  }
}

class FakeFinder implements CuriosityFinder {
  int calls = 0;
  CuriosityPair pair = CuriosityPair(
    song: Curiosity(
      'A story',
      Uri.parse('https://it.wikipedia.org/wiki/X'),
      'it',
    ),
    artist: Curiosity(
      'A bio',
      Uri.parse('https://it.wikipedia.org/wiki/Y'),
      'it',
    ),
  );

  @override
  Future<CuriosityPair> find(
    String title,
    String artist,
    String lang, {
    String? isrc,
    int durationMs = 0,
    cancel,
  }) async {
    calls++;
    return pair;
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

/// An [EnrichmentService] over an in-memory DB with every source faked.
class EnrichRig {
  EnrichRig._(this.tmp);

  factory EnrichRig() {
    final r = EnrichRig._(Directory.systemTemp.createTempSync('enrich_rig'));
    r.db = AppDatabase(NativeDatabase.memory());
    r.repo = TrackRepository(r.db);
    r.credits = CreditsRepository(r.db);
    r.web = EnrichWeb();
    r.chain = FakeChain(r.web);
    r.finder = FakeFinder();
    r.svc = EnrichmentService(
      db: r.db,
      tracks: r.repo,
      covers: CoverStore(Directory(p.join(r.tmp.path, 'c'))),
      itunes: ItunesClient(r.web),
      gw: FakeGw(),
      musicBrainz: MusicBrainzClient(r.web, pause: (_) async {}),
      deezer: DeezerClient(r.web),
      creditsRepo: r.credits,
      useDeezer: () => r.deezerMeta,
      useCredits: () => true,
      lrclib: LrclibClient(r.web),
      lyricsChain: r.chain,
      curiosities: CuriosityService(
        finder: r.finder,
        tracks: r.repo,
        artistInfos: ArtistInfoRepository(r.db),
      ),
      wikipedia: WikipediaClient(r.web),
      web: r.web,
      language: () => 'it',
      limiter: RateLimiter(minGap: Duration.zero),
    );
    return r;
  }

  final Directory tmp;
  bool deezerMeta = false;
  late final AppDatabase db;
  late final TrackRepository repo;
  late final CreditsRepository credits;
  late final EnrichWeb web;
  late final FakeChain chain;
  late final FakeFinder finder;
  late final EnrichmentService svc;

  Future<void> dispose() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  }

  Future<int> add({
    String? album,
    String? genre,
    int? year,
    int? trackNumber,
    String? plain,
    String? synced,
    bool userEdited = false,
    int coverSource = 0,
    String? curiosities,
  }) async {
    final id = await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
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
            album: Value(album),
            genre: Value(genre),
            year: Value(year),
            trackNumber: Value(trackNumber),
            lyricsPlain: Value(plain),
            lyricsSynced: Value(synced),
            curiosities: Value(curiosities),
            userEdited: Value(userEdited),
            coverSource: Value(coverSource),
          ),
        );
    return id;
  }

  Future<TrackEnrichData?> enrichOf(int id) => credits.enrichOf(id);
}
