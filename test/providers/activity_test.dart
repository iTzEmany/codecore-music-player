import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/providers/online_providers.dart';
import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/enrichment_service.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/scanner/library_scanner.dart';
import 'package:codecore/services/share/offers.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  YtResult yt(String id) => YtResult(id: id, title: 'Titolo $id', channel: 'C', duration: null);

  test('nothing running → empty', () {
    final s = buildActivity(
      scan: const ScanState(),
      enrich: const EnrichJobState(),
      downloads: const [],
      outgoing: const [],
    );
    expect(s.isEmpty, isTrue);
  });

  test('scan, enrichment, downloads and transfers are aggregated', () {
    final offer = OutgoingOffer(
        offerId: 'o', toId: 'x', toName: 'Telefono', token: 't', entries: {});
    final done = OutgoingOffer(
        offerId: 'p', toId: 'x', toName: 'PC', token: 't', entries: {})
      ..status = OfferStatus.done;
    final s = buildActivity(
      scan: const ScanState(
          running: true, progress: ScanProgress(done: 10, total: 40)),
      enrich: const EnrichJobState(
          running: true, progress: BatchProgress(done: 1, total: 4)),
      downloads: [
        DownloadItem(
            id: 1,
            result: yt('a'),
            status: DownloadStatus.downloading,
            progress: 0.5),
        DownloadItem(
            id: 2, result: yt('b'), status: DownloadStatus.done),
        DownloadItem(
            id: 3, result: yt('c'), status: DownloadStatus.failed),
      ],
      outgoing: [offer, done],
    );
    expect(s.running.map((e) => e.kind), [
      ActivityKind.scan,
      ActivityKind.enrich,
      ActivityKind.download,
      ActivityKind.transfer,
    ]);
    expect(s.running.first.progress, 0.25);
    expect(s.running[2].progress, 0.5);
    expect(s.completed.length, 3);
    expect(s.completed.where((e) => e.failed).length, 1);
    expect(s.running[2].cancellable, isTrue);
    expect(s.running.first.cancellable, isFalse);
  });

  test('a download waiting to retry is still running and says when', () {
    final s = buildActivity(
      scan: const ScanState(),
      enrich: const EnrichJobState(),
      downloads: [
        DownloadItem(
            id: 1,
            result: yt('a'),
            status: DownloadStatus.waitingRetry,
            attempt: 2,
            retryDelay: const Duration(seconds: 20)),
      ],
      outgoing: const [],
    );
    final item = s.running.single;
    expect(item.kind, ActivityKind.download);
    expect(item.retryDelaySec, 20);
    expect(item.done, 2);
    expect(item.total, 3);
    expect(item.cancellable, isTrue);
    expect(s.completed, isEmpty);
  });

  test('the downloads of an import are followed in its own screen, not here', () {
    const r = YtResult(id: 'v', title: 'Song', channel: 'Band', duration: null);
    final s = buildActivity(
      scan: const ScanState(),
      enrich: const EnrichJobState(),
      downloads: [
        DownloadItem(id: 1, result: r, status: DownloadStatus.downloading, tag: importTag(4, 2)),
        const DownloadItem(id: 2, result: r, status: DownloadStatus.downloading),
        DownloadItem(id: 3, result: r, status: DownloadStatus.done, tag: importTag(4, 3)),
      ],
      outgoing: const [],
    );
    expect(s.running.map((a) => a.key), ['dl-2']);
    expect(s.completed.map((a) => a.key), ['dl-3'], reason: 'still recorded in the Registro');
  });

  test('«Controlla ora» is a running line that cannot be cancelled', () {
    final s = buildActivity(
      scan: const ScanState(),
      enrich: const EnrichJobState(),
      downloads: const [],
      outgoing: const [],
      releases: true,
    );
    expect(s.running.single.kind, ActivityKind.releases);
    expect(s.running.single.cancellable, isFalse);
  });
}
