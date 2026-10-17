import 'dart:io';

import '../../core/app_log.dart';
import 'duplicate_finder.dart';

typedef FileDeleter = Future<void> Function(String path);

/// What a «delete the files» pass did, per file.
class DeleteReport {
  DeleteReport({
    required this.deleted,
    required this.failed,
    required this.skipped,
  });

  /// Gone from disk (including files that were already gone).
  final List<DupEntry> deleted;

  /// Could not be deleted, with the system's reason.
  final Map<DupEntry, String> failed;

  /// Never touched: the same file as the one kept, or the kept track itself.
  final List<DupEntry> skipped;

  int get freedBytes => deleted.fold(0, (n, e) => n + e.sizeBytes);
}

Future<void> _deleteFile(String path) => File(path).delete();

Future<String> _realPath(String path) async {
  try {
    return await File(path).resolveSymbolicLinks();
  } on FileSystemException {
    return path;
  }
}

/// Deletes the files of [drops] (the duplicates left hidden after a merge).
/// Never the kept file: a duplicate that resolves to the same file as
/// [keeper] (a link, a hard-linked path) is skipped. A failure on one file
/// (read-only folder, Android's storage rules) is collected and the rest go
/// on. Only called after two explicit confirmations.
Future<DeleteReport> deleteDuplicateFiles(
  DupEntry keeper,
  List<DupEntry> drops, {
  FileDeleter deleter = _deleteFile,
}) async {
  final deleted = <DupEntry>[];
  final failed = <DupEntry, String>{};
  final skipped = <DupEntry>[];
  final keeperReal = await _realPath(keeper.path);
  for (final d in drops) {
    if (d.id == keeper.id || d.path == keeper.path) {
      skipped.add(d);
      continue;
    }
    if (!await File(d.path).exists()) {
      deleted.add(d);
      continue;
    }
    if (await _realPath(d.path) == keeperReal) {
      skipped.add(d);
      continue;
    }
    try {
      await deleter(d.path);
      deleted.add(d);
    } on Object catch (e, st) {
      AppLog.w('delete duplicate failed: ${d.path}', e, st);
      failed[d] = e is FileSystemException
          ? (e.osError?.message ?? e.message)
          : '$e';
    }
  }
  return DeleteReport(deleted: deleted, failed: failed, skipped: skipped);
}
