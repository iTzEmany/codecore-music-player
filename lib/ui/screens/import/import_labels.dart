import '../../../data/repositories/import_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/import/import_options.dart';
import '../../../services/import/import_row_phase.dart';
import '../../../services/import/playlist_import_service.dart';
import '../../../services/online/download_queue.dart';

/// Text for the codes kept in the database.
String importStatusLabel(AppLocalizations l, ImportItemStatus s) => switch (s) {
      ImportItemStatus.pending => l.importStatusPending,
      ImportItemStatus.queued => l.importStatusQueued,
      ImportItemStatus.downloaded => l.importStatusDownloaded,
      ImportItemStatus.linked => l.importStatusLinked,
      ImportItemStatus.review => l.importStatusReview,
      ImportItemStatus.notFound => l.importStatusNotFound,
      ImportItemStatus.failed => l.importStatusFailed,
      ImportItemStatus.skipped => l.importStatusSkipped,
      ImportItemStatus.planned => l.importStatusPlanned,
      ImportItemStatus.removed => l.importStatusRemoved,
    };

String importNoteLabel(AppLocalizations l, String code) => switch (code) {
      ImportNote.noResults => l.importNoteNoResults,
      ImportNote.lowScore => l.importNoteLowScore,
      ImportNote.linkOnly => l.importNoteLinkOnly,
      ImportNote.youtubeOff => l.importNoteYoutubeOff,
      ImportNote.downloadFailed => l.importNoteDownloadFailed,
      ImportNote.lengthOff => l.importNoteLengthOff,
      ImportNote.unchanged => l.importNoteUnchanged,
      _ => code,
    };

/// The phase of one song as the import screen writes it under the title.
String rowPhaseLabel(AppLocalizations l, RowPhase p, DownloadItem? download) => switch (p) {
      RowPhase.waiting => l.importStatusPending,
      RowPhase.searching => l.importPhaseSearching,
      RowPhase.queued => l.importStatusQueued,
      RowPhase.downloading => (download?.progress ?? 0) > 0
          ? l.importPhaseDownloading((download!.progress * 100).round())
          : l.importPhaseDownloadStart,
      RowPhase.retrying => l.importPhaseRetry(download?.retryDelay?.inSeconds ?? 0),
      RowPhase.enriching => l.importPhaseEnriching,
      RowPhase.downloaded => l.importStatusDownloaded,
      RowPhase.linked => l.importStatusLinked,
      RowPhase.review => l.importStatusReview,
      RowPhase.notFound => l.importStatusNotFound,
      RowPhase.failed => l.importStatusFailed,
      RowPhase.skipped => l.importStatusSkipped,
      RowPhase.planned => l.importStatusPlanned,
      RowPhase.removed => l.importStatusRemoved,
    };

/// Why the engine waits, and until when («riprendo alle 04:32»). The time is
/// written by hand: the notification is made also before the app's date
/// formats are loaded.
String importWaitLabel(AppLocalizations l, ImportWait w) {
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(w.until.hour)}:${two(w.until.minute)}';
  return w.reason == ImportEventKind.rateLimited
      ? l.importWaitRateLimited(time)
      : l.importWaitNetwork(time);
}

/// Why an import stopped by itself (null for the events that are no stop).
String? importStopText(AppLocalizations l, ImportEventKind k) => switch (k) {
      ImportEventKind.rateLimited => l.ytErrRateLimited,
      ImportEventKind.network => l.ytErrNetwork,
      ImportEventKind.toolMissing => l.ytErrToolMissing,
      ImportEventKind.toolOutdated => l.ytErrToolOutdated,
      ImportEventKind.failing => l.csvImportFailing,
      ImportEventKind.completed || ImportEventKind.planned => null,
    };
