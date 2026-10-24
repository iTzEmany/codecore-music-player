import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/library/track_file_sync.dart' show stampTrack;
import '../services/tags/safe_tag_writer.dart';
import '../services/tags/tag_backups.dart';
import '../services/tags/tag_writer.dart';
import 'database_providers.dart';
import 'library_providers.dart';

/// Puts a saved original back and records the new size and date of the file.
class TagBackupOps {
  TagBackupOps(this._ref);

  final Ref _ref;

  Future<void> restore(TagBackup b) async {
    final stamp = await (await _ref.read(tagBackupStoreProvider.future)).restore(b);
    await stampTrack(_ref.read(databaseProvider), b.path, stamp);
  }
}

final tagBackupOpsProvider = Provider<TagBackupOps>(TagBackupOps.new);

/// The saved originals, newest first. Follows the store: a new or deleted
/// backup refreshes it.
final tagBackupsProvider = FutureProvider.autoDispose<List<TagBackup>>((ref) async {
  final store = await ref.watch(tagBackupStoreProvider.future);
  final sub = store.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return store.list();
});

/// Why the file at the path cannot be rewritten (null = it can).
final tagWritableProvider = FutureProvider.autoDispose
    .family<TagWriteReason?, String>(
      (ref, path) async =>
          (await ref.watch(safeTagWriterProvider.future)).check(path),
    );

/// The extension used in messages, e.g. `wma`.
String tagFormatOf(String path) => SafeTagWriter.formatOf(path);
