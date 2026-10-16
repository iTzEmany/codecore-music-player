import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/play_history_repository.dart';
import '../data/repositories/stats_queries.dart';
import 'database_providers.dart';

/// The newest [limit] listens with their tracks (argument: how many).
final historyProvider =
    StreamProvider.autoDispose.family<List<HistoryEntry>, int>(
      (ref, limit) =>
          ref.watch(playHistoryRepositoryProvider).watchHistory(limit: limit),
    );

final statsQueriesProvider = Provider<StatsQueries>(
  (ref) => StatsQueries(ref.watch(databaseProvider)),
);

/// The stats of a month or a year; the key says which (year, month, isYear).
final periodStatsProvider = StreamProvider.autoDispose
    .family<PeriodStats, ({bool year, int y, int m})>((ref, k) {
      final p = k.year ? StatsPeriod.year(k.y) : StatsPeriod.month(k.y, k.m);
      return ref.watch(statsQueriesProvider).watchPeriod(p);
    });

/// How many listens this month so far (the Home card needs ten).
final monthPlaysProvider = StreamProvider.autoDispose<int>((ref) {
  final now = DateTime.now();
  return ref
      .watch(statsQueriesProvider)
      .watchPlaysIn(StatsPeriod.month(now.year, now.month));
});
