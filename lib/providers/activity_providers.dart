import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online/download_queue.dart';
import '../services/share/offers.dart';
import 'import_providers.dart';
import 'library_providers.dart';
import 'online_providers.dart';
import 'share_hub.dart';
import 'youtube_providers.dart';

enum ActivityKind { scan, enrich, download, transfer, import }

/// One line of the Activity centre. [progress] is 0..1, null = indeterminate.
class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.key,
    required this.name,
    this.done = 0,
    this.total = 0,
    this.progress,
    this.running = true,
    this.failed = false,
    this.paused = false,
    this.ref,
  });

  final ActivityKind kind;
  final String key;

  /// Download title / device name (null for scan and enrichment).
  final String? name;
  final int done, total;
  final double? progress;
  final bool running, failed;

  /// A CSV import waiting for the user (still listed among the running ones).
  final bool paused;

  /// The download id, the [OutgoingOffer] or the import id, used to cancel.
  final Object? ref;

  bool get cancellable =>
      running &&
      (kind == ActivityKind.download ||
          kind == ActivityKind.transfer ||
          kind == ActivityKind.import ||
          kind == ActivityKind.enrich);
}

class ActivityState {
  const ActivityState(this.running, this.completed);

  final List<ActivityItem> running, completed;

  bool get isEmpty => running.isEmpty && completed.isEmpty;
}

/// Pure aggregation of what the app is doing in the background.
ActivityState buildActivity({
  required ScanState scan,
  required EnrichJobState enrich,
  required List<DownloadItem> downloads,
  required List<OutgoingOffer> outgoing,
  List<ImportProgress> imports = const [],
}) {
  final running = <ActivityItem>[];
  final completed = <ActivityItem>[];

  if (scan.running) {
    final p = scan.progress;
    running.add(
      ActivityItem(
        kind: ActivityKind.scan,
        key: 'scan',
        name: null,
        done: p?.done ?? 0,
        total: p?.total ?? 0,
        progress: (p == null || p.total == 0) ? null : p.done / p.total,
      ),
    );
  }
  if (enrich.running) {
    final p = enrich.progress;
    running.add(
      ActivityItem(
        kind: ActivityKind.enrich,
        key: 'enrich',
        name: null,
        done: p?.done ?? 0,
        total: p?.total ?? 0,
        progress: (p == null || p.total == 0) ? null : p.done / p.total,
      ),
    );
  }
  for (final i in imports) {
    running.add(
      ActivityItem(
        kind: ActivityKind.import,
        key: 'imp-${i.id}',
        name: i.name,
        done: i.done,
        total: i.total,
        progress: i.fraction,
        paused: i.paused,
        ref: i.id,
      ),
    );
  }
  for (final d in downloads) {
    final active =
        d.status == DownloadStatus.queued ||
        d.status == DownloadStatus.downloading;
    final item = ActivityItem(
      kind: ActivityKind.download,
      key: 'dl-${d.id}',
      name: d.result.title,
      progress: d.status == DownloadStatus.downloading ? d.progress : null,
      running: active,
      failed: d.status == DownloadStatus.failed,
      ref: d.id,
    );
    (active ? running : completed).add(item);
  }
  for (final o in outgoing) {
    final item = ActivityItem(
      kind: ActivityKind.transfer,
      key: 'tx-${o.offerId}',
      name: o.toName,
      total: o.entries.length,
      progress: null,
      running: o.open,
      failed:
          o.status == OfferStatus.failed ||
          o.status == OfferStatus.declined ||
          o.status == OfferStatus.expired,
      ref: o,
    );
    (o.open ? running : completed).add(item);
  }
  return ActivityState(running, completed);
}

/// Keys of the completed entries the user cleared with «Pulisci».
class DismissedActivityNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void dismiss(Iterable<String> keys) => state = {...state, ...keys};
}

final dismissedActivityProvider =
    NotifierProvider<DismissedActivityNotifier, Set<String>>(
      DismissedActivityNotifier.new,
    );

final activityProvider = Provider<ActivityState>((ref) {
  final s = buildActivity(
    scan: ref.watch(scanStateProvider),
    enrich: ref.watch(enrichJobProvider),
    downloads: ref.watch(downloadsProvider),
    outgoing: ref.watch(shareHubProvider.select((h) => h.outgoing)),
    imports: ref.watch(importProgressProvider),
  );
  final hidden = ref.watch(dismissedActivityProvider);
  if (hidden.isEmpty) return s;
  return ActivityState(s.running, [
    for (final c in s.completed)
      if (!hidden.contains(c.key)) c,
  ]);
});
