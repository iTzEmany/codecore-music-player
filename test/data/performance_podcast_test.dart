import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/data/repositories/podcast_repository.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/podcast/podcast_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A feed with [n] episodes, the way a long-running show has them.
PodcastFeed bigFeed(int n) => PodcastFeed(
      title: 'Big Show',
      author: 'Someone',
      episodes: [
        for (var i = 0; i < n; i++)
          PodcastEpisodeInfo(
            guid: 'guid-$i',
            title: 'Episode $i: a title of a normal length for a show',
            audioUrl: 'https://cdn.example.org/show/$i.mp3',
            publishedAt: DateTime.utc(2020).add(Duration(days: i)),
            duration: Duration(minutes: 20 + i % 40),
            mimeType: 'audio/mpeg',
            sizeBytes: 30000000 + i,
            description: 'Show notes of episode $i. ' * 20,
          ),
      ],
    );

void main() {
  final margin = int.tryParse(Platform.environment['CODECORE_PERF_MARGIN'] ?? '') ?? 2;

  test('a 2 000-episode feed is saved, listed and refreshed fast, and does not slow the music views', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PodcastRepository(db);
    // 20 000 songs in the library, as in the other performance tests.
    await db.batch((b) => b.insertAll(db.tracks, [
          for (var i = 0; i < 20000; i++)
            TracksCompanion.insert(
                path: '/m/$i.mp3', title: 'Song $i', albumKey: 'a|${i % 1500}', format: 'mp3',
                sizeBytes: 1, mtimeMs: 1, addedAt: i),
        ]));
    final feed = bigFeed(2000);

    final sw = Stopwatch()..start();
    final id = await repo.subscribe('https://x/big', feed, now: 1);
    final saved = sw.elapsedMilliseconds;

    sw
      ..reset()
      ..start();
    final rows = await repo.watchEpisodes(id).first;
    final listed = sw.elapsedMilliseconds;

    sw
      ..reset()
      ..start();
    final none = await repo.upsertEpisodes(id, feed.episodes);
    final again = sw.elapsedMilliseconds;

    sw
      ..reset()
      ..start();
    final more = await repo.upsertEpisodes(id, bigFeed(2010).episodes);
    final grown = sw.elapsedMilliseconds;

    sw
      ..reset()
      ..start();
    final summary = await repo.watchPodcasts().first;
    final summarised = sw.elapsedMilliseconds;

    sw
      ..reset()
      ..start();
    final music = await TrackRepository(db).watchTracks().first;
    final albums = await LibraryQueries(db).watchAlbums().first;
    final musicMs = sw.elapsedMilliseconds;

    expect(rows, hasLength(2000));
    expect(rows.first.episode.guid, 'guid-1999', reason: 'newest first');
    expect(none, 0);
    expect(more, 10);
    expect(summary.single.episodeCount, 2010);
    expect(music, hasLength(20000));
    expect(albums, hasLength(1500), reason: 'the 2 000 episodes add no album and no track');

    // ignore: avoid_print
    print('podcast perf: save=$saved ms, list=$listed ms, no-op refresh=$again ms, +10 episodes=$grown ms, '
        'summary=$summarised ms, music views with episodes around=$musicMs ms');
    expect(saved, lessThan(1500 * margin), reason: 'saving 2 000 episodes');
    expect(listed, lessThan(500 * margin), reason: 'listing them (the page opens in under a second)');
    expect(again, lessThan(800 * margin), reason: 'a refresh with nothing new');
    expect(grown, lessThan(800 * margin), reason: 'a refresh with 10 new');
    expect(summarised, lessThan(300 * margin));
  });
}
