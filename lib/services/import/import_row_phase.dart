import '../../data/db/app_database.dart';
import '../../data/repositories/import_repository.dart';
import '../online/download_queue.dart';
import 'playlist_import_service.dart';

/// Where one song of an import is, as the import screen shows it: the state
/// kept in the database, made precise by what is happening right now (the
/// search, the download and its progress, the tags and cover).
enum RowPhase {
  waiting,
  searching,
  queued,
  downloading,
  retrying,
  enriching,
  downloaded,
  linked,
  review,
  notFound,
  failed,
  skipped,
  planned,
  removed;

  /// Something is happening to the song now.
  bool get active =>
      this == searching || this == queued || this == downloading || this == retrying || this == enriching;

  /// The song needs the user (a choice to make, or nothing found).
  bool get problem => this == review || this == notFound || this == failed;

  /// Nothing more will happen to it.
  bool get settled => this == downloaded || this == linked || this == skipped || this == removed;
}

/// [steps] are the rows the engine is on; [enriching] the songs waiting for
/// or in the background enrichment; [download] the queue's entry for the row.
RowPhase rowPhase(
  PlaylistImportItem item, {
  ImportSteps steps = const {},
  Set<int> enriching = const {},
  DownloadItem? download,
}) {
  switch (steps[(item.importId, item.rowIndex)]) {
    case ImportStepKind.searching:
      return RowPhase.searching;
    case ImportStepKind.enriching:
      return RowPhase.enriching;
    case null:
      break;
  }
  if (item.state == ImportItemStatus.downloaded && enriching.contains(item.trackId)) {
    return RowPhase.enriching;
  }
  return switch (item.state) {
    ImportItemStatus.pending => RowPhase.waiting,
    ImportItemStatus.queued => switch (download?.status) {
        DownloadStatus.downloading => RowPhase.downloading,
        DownloadStatus.waitingRetry => RowPhase.retrying,
        _ => RowPhase.queued,
      },
    ImportItemStatus.downloaded => RowPhase.downloaded,
    ImportItemStatus.linked => RowPhase.linked,
    ImportItemStatus.review => RowPhase.review,
    ImportItemStatus.notFound => RowPhase.notFound,
    ImportItemStatus.failed => RowPhase.failed,
    ImportItemStatus.skipped => RowPhase.skipped,
    ImportItemStatus.planned => RowPhase.planned,
    ImportItemStatus.removed => RowPhase.removed,
  };
}
