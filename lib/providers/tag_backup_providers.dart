import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tags/safe_tag_writer.dart';
import '../services/tags/tag_backups.dart';
import '../services/tags/tag_writer.dart';
import 'library_providers.dart';

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
