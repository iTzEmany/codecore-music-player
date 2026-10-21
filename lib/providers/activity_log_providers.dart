import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/import/import_chain.dart';
import '../services/import/playlist_import_service.dart';
import 'activity_providers.dart';
import 'database_providers.dart';
import 'import_providers.dart';
import 'podcast_providers.dart';
import 'youtube_providers.dart';

/// One line of the Registro: something that ended, and when.
class LogEntry {
  const LogEntry({required this.at, this.item, this.importName, this.event});

  final DateTime at;

  /// A download, an episode or a transfer that ended (done or not).
  final ActivityItem? item;

  /// An import that ended or stopped, with why.
  final String? importName;
  final ImportEventKind? event;

  bool get failed =>
      (item?.failed ?? false) ||
      (event != null && event != ImportEventKind.completed && event != ImportEventKind.planned);
}

/// What ended in the background, newest first (at most [limit] lines, for this
/// session). Kept alive from the app's root, so the times are the real ones
/// also while the Activity centre is closed.
class ActivityLogNotifier extends Notifier<List<LogEntry>> {
  static const limit = 500;
  final _logged = <String>{};

  @override
  List<LogEntry> build() {
    ref.listen<ActivityState>(activityProvider, (_, s) => _record(s));
    ref.listen<AsyncValue<ImportEvent>>(importEventsProvider, (_, e) {
      final event = e.value;
      if (event != null) unawaited(_recordImport(event));
    });
    return const [];
  }

  void _record(ActivityState s) {
    final now = DateTime.now();
    final fresh = [
      for (final c in s.completed)
        if (_logged.add(c.key)) LogEntry(at: now, item: c),
    ];
    if (fresh.isNotEmpty) _add(fresh);
  }

  Future<void> _recordImport(ImportEvent e) async {
    final imp = await ref.read(importRepositoryProvider).get(e.importId);
    if (!ref.mounted) return;
    _add([
      LogEntry(
        at: DateTime.now(),
        importName: imp == null ? null : importLabel(imp.sourceName),
        event: e.kind,
      ),
    ]);
  }

  void _add(List<LogEntry> fresh) {
    final all = [...fresh.reversed, ...state];
    state = all.length > limit ? all.sublist(0, limit) : all;
  }

  /// Empties the Registro and forgets the finished downloads behind it.
  void clear() {
    ref.read(downloadsProvider.notifier).clearFinished();
    ref.read(podcastDownloadsProvider.notifier).clearFinished();
    state = const [];
  }
}

final activityLogProvider =
    NotifierProvider<ActivityLogNotifier, List<LogEntry>>(ActivityLogNotifier.new);
