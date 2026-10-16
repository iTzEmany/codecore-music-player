import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/play_history_repository.dart';
import 'database_providers.dart';

/// The newest [limit] listens with their tracks (argument: how many).
final historyProvider =
    StreamProvider.autoDispose.family<List<HistoryEntry>, int>(
      (ref, limit) =>
          ref.watch(playHistoryRepositoryProvider).watchHistory(limit: limit),
    );
