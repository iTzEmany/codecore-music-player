import '../../data/db/app_database.dart';
import '../../data/repositories/import_repository.dart';
import 'csv_parser.dart';

/// The result of an import as a CSV the user can open in a spreadsheet: one
/// line per CSV row, with why it was not downloaded. [status] and [note] turn
/// the stored codes into text in the user's language.
String importOutcomeCsv(
  List<PlaylistImportItem> items, {
  required String Function(ImportItemStatus) status,
  required String Function(String code) note,
  required List<String> header,
}) {
  return writeCsv([
    header,
    for (final it in items)
      if (it.state != ImportItemStatus.removed)
        [
          '${it.rowIndex + 1}',
          it.title,
          it.artistList.join('; '),
          it.album ?? '',
          it.durationMs == null ? '' : '${it.durationMs}',
          it.isrc ?? '',
          status(it.state),
          it.note == null ? '' : note(it.note!),
          it.videoId == null
              ? ''
              : 'https://music.youtube.com/watch?v=${it.videoId}',
          it.score == null ? '' : it.score!.toStringAsFixed(2),
        ],
  ]);
}
