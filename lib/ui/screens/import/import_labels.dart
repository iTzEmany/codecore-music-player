import '../../../data/repositories/import_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/import/import_options.dart';

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
      _ => code,
    };
