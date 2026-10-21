import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/data/repositories/import_repository.dart';
import 'package:codecore/services/import/import_row_phase.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

PlaylistImportItem _item(ImportItemStatus s, {int importId = 7, int row = 3}) => PlaylistImportItem(
      importId: importId,
      rowIndex: row,
      title: 'Song',
      artists: 'Band',
      status: s.index,
    );

DownloadItem _dl(DownloadStatus s) => DownloadItem(
      id: 1,
      result: const YtResult(id: 'v', title: 'Song', channel: 'Band', duration: null),
      status: s,
      tag: importTag(7, 3),
    );

void main() {
  test('what the engine does now comes first', () {
    const searching = {(7, 3): ImportStepKind.searching};
    expect(rowPhase(_item(ImportItemStatus.pending), steps: searching), RowPhase.searching);
    const enriching = {(7, 3): ImportStepKind.enriching, (7, 4): ImportStepKind.searching};
    expect(rowPhase(_item(ImportItemStatus.queued), steps: enriching), RowPhase.enriching);
    expect(rowPhase(_item(ImportItemStatus.pending, row: 4), steps: enriching), RowPhase.searching,
        reason: 'a search and the tags of another row at the same time');
    expect(rowPhase(_item(ImportItemStatus.pending, row: 5), steps: searching), RowPhase.waiting,
        reason: 'another row');
    expect(rowPhase(_item(ImportItemStatus.pending, importId: 8), steps: searching), RowPhase.waiting,
        reason: 'the same row number of another block');
  });

  test('a saved song waiting for its lyrics and tags is still being enriched', () {
    final saved = _item(ImportItemStatus.downloaded).copyWith(trackId: const Value(42));
    expect(rowPhase(saved, enriching: {42}), RowPhase.enriching);
    expect(rowPhase(saved, enriching: {41}), RowPhase.downloaded);
    expect(rowPhase(_item(ImportItemStatus.downloaded)), RowPhase.downloaded);
  });

  test('a queued row follows its download', () {
    expect(rowPhase(_item(ImportItemStatus.queued)), RowPhase.queued);
    expect(rowPhase(_item(ImportItemStatus.queued), download: _dl(DownloadStatus.downloading)),
        RowPhase.downloading);
    expect(rowPhase(_item(ImportItemStatus.queued), download: _dl(DownloadStatus.waitingRetry)),
        RowPhase.retrying);
  });

  test('the stored states, and which need the user', () {
    expect(rowPhase(_item(ImportItemStatus.downloaded)), RowPhase.downloaded);
    expect(rowPhase(_item(ImportItemStatus.notFound)).problem, isTrue);
    expect(rowPhase(_item(ImportItemStatus.review)).problem, isTrue);
    expect(rowPhase(_item(ImportItemStatus.linked)).settled, isTrue);
    expect(RowPhase.downloading.active, isTrue);
    expect(RowPhase.waiting.active, isFalse);
  });
}
