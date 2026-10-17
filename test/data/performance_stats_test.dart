import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:codecore/data/repositories/stats_queries.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/services/library/rules/rule_parser.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 20 000 tracks and 100 000 listens over a year (docs fase 20.10): the recap
/// and the search with operators stay interactive. On a shared CI runner the
/// budgets get a ×2 margin.
const _tracks = 20000;
const _plays = 100000;

Future<int> _ms(Future<Object?> Function() f) async {
  final sw = Stopwatch()..start();
  await f();
  return sw.elapsedMilliseconds;
}

void main() {
  // ×2 by default: the suite runs these next to a hundred other test files, so
  // the clock includes the neighbours. CODECORE_PERF_MARGIN=1 for a quiet run.
  final margin = int.tryParse(Platform.environment['CODECORE_PERF_MARGIN'] ?? '') ?? 2;
  late AppDatabase db;
  late TrackRepository repo;
  final year = DateTime.now().year;

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrackRepository(db);
    final genres = ['Rock', 'Jazz', 'Pop', 'Electronic', 'Classical', 'Folk'];
    await db.batch((b) {
      b.insertAll(db.tracks, [
        for (var i = 0; i < _tracks; i++)
          TracksCompanion.insert(
            path: '/m/${i % 500}/song $i.${i % 4 == 0 ? 'flac' : 'mp3'}',
            title: i % 17 == 0 ? 'Song $i (live)' : 'Song $i',
            artist: Value('Artist ${i % 500}'),
            album: Value('Album ${i % 2000}'),
            albumKey: 'artist ${i % 500}|album ${i % 2000}',
            genre: Value(genres[i % genres.length]),
            year: Value(1960 + i % 65),
            durationMs: Value(120000 + (i % 400) * 1000),
            format: i % 4 == 0 ? 'flac' : 'mp3',
            sizeBytes: 1000,
            mtimeMs: i,
            addedAt: DateTime.now().millisecondsSinceEpoch - (i % 900) * 86400000,
            playCount: Value(i % 13),
            isFavorite: Value(i % 11 == 0),
          ),
      ]);
    });
    final first = DateTime(year).millisecondsSinceEpoch;
    final span = DateTime(year + 1).millisecondsSinceEpoch - first;
    for (var start = 0; start < _plays; start += 5000) {
      await db.batch((b) {
        b.insertAll(db.plays, [
          for (var i = start; i < start + 5000; i++)
            PlaysCompanion.insert(
              trackId: 1 + (i * 7919) % _tracks,
              playedAt: first + (i * 315361 + (i * i % 7919) * 1000) % span,
              msPlayed: Value(60000 + (i % 240) * 1000),
            ),
        ]);
      });
    }
    // A few tags, for the `tag:` rules.
    final tag = await db.into(db.userTags).insert(UserTagsCompanion.insert(name: 'Live'));
    await db.batch((b) {
      b.insertAll(db.trackTags, [
        for (var i = 1; i <= _tracks; i += 40)
          TrackTagsCompanion.insert(trackId: i, tagId: tag),
      ]);
    });
  });
  tearDownAll(() => db.close());

  test('the yearly recap and the monthly one stay under budget', () async {
    final stats = StatsQueries(db);
    final yearMs = await _ms(() => stats.period(StatsPeriod.year(year)));
    final monthMs = await _ms(() => stats.period(StatsPeriod.month(year, 6)));
    final cur = await stats.period(StatsPeriod.year(year));
    // ignore: avoid_print
    print('perf stats ms: year=$yearMs month=$monthMs (${cur.plays} listens)');
    expect(cur.plays, _plays);
    expect(cur.msPerBucket, hasLength(12));
    expect(cur.msPerBucket.every((m) => m > 0), isTrue, reason: 'listens in every month');
    expect(yearMs, lessThan(300 * margin), reason: 'annual recap');
    expect(monthMs, lessThan(200 * margin), reason: 'monthly recap');
  });

  test('searching with operators stays under budget', () async {
    // Selective searches (a few hundred matches at most): the budget of the
    // document. Broad ones return thousands of rows, which cost what listing
    // that many tracks costs (see performance_test.dart), so they get more.
    final selective = {
      'artist+years+negation': 'artista:"artist 7" anno:1990..1999 -live',
      'free text + flag': 'song 19 preferiti',
      'tag': 'tag:live',
      'numbers': 'durata>5m aggiunto<30g ascolti>3 formato:flac artista:"artist 1"',
    };
    final broad = {
      'or': 'genere:rock OR genere:jazz',
      'only a negation': '-live',
    };
    final times = <String, int>{};
    for (final e in {...selective, ...broad}.entries) {
      final rules = parseRules(e.value).expr;
      times[e.key] = await _ms(() => repo.tracksByRules(rules));
    }
    final count = await _ms(() => repo.countByRules(parseRules('genere:rock').expr));
    // ignore: avoid_print
    print('perf rules ms: $times count=$count');
    for (final k in selective.keys) {
      expect(times[k], lessThan(80 * margin), reason: k);
    }
    for (final k in broad.keys) {
      expect(times[k], lessThan(600 * margin), reason: k);
    }
    expect(count, lessThan(80 * margin));
  });

  test('the history page and the most played stay under budget', () async {
    final history = PlayHistoryRepository(db);
    final page = await _ms(() => history.watchHistory(limit: 200).first);
    final more = await _ms(() => history.watchHistory(limit: 200, beforePlayedAt: DateTime(year, 6).millisecondsSinceEpoch).first);
    // ignore: avoid_print
    print('perf history ms: page=$page more=$more');
    expect(page, lessThan(80 * margin));
    expect(more, lessThan(80 * margin));
  });
}
