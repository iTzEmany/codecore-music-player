import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/tag_backup_providers.dart';
import '../../../services/library/track_file_sync.dart';
import '../../../services/tags/tag_backups.dart';
import '../../../services/tags/tag_writer.dart';
import '../../widgets/confirm.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/tag_write_ui.dart';

/// Settings → Tag backups: the original of every file whose tags were
/// rewritten, with «Restore original» and «Delete backup».
class TagBackupsScreen extends ConsumerWidget {
  const TagBackupsScreen({super.key});

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    TagBackup b,
  ) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirm(
      context,
      title: l.tagBackupRestore,
      body: l.tagBackupRestoreBody(p.basename(b.path)),
      confirmLabel: l.tagBackupRestore,
    );
    if (!ok) return;
    String msg;
    try {
      final store = await ref.read(tagBackupStoreProvider.future);
      final stamp = await store.restore(b);
      await stampTrack(ref.read(databaseProvider), b.path, stamp);
      msg = l.tagBackupRestored;
    } on TagWriteException catch (e) {
      msg = l.tagBackupRestoreFailed(tagReasonText(l, e.reason));
    } on Object catch (e, st) {
      AppLog.e('tag backup restore failed', e, st);
      msg = l.tagBackupRestoreFailed(tagReasonText(l, TagWriteReason.ioError));
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TagBackup b,
  ) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showConfirm(
      context,
      title: l.tagBackupDelete,
      body: l.tagBackupDeleteBody,
      confirmLabel: l.tagBackupDelete,
      destructive: true,
    );
    if (!ok) return;
    await (await ref.read(tagBackupStoreProvider.future)).delete(b);
    ref.invalidate(tagBackupsProvider);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l.tagBackupDeleted)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final backups = ref.watch(tagBackupsProvider).value ?? const <TagBackup>[];
    final fmt = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).add_Hm();
    return Scaffold(
      appBar: AppBar(title: Text(l.tagBackupsTitle)),
      body: backups.isEmpty
          ? EmptyState(icon: Icons.history_rounded, message: l.tagBackupsEmpty)
          : ListView.builder(
              itemCount: backups.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.tagBackupsHint),
                  );
                }
                final b = backups[i - 1];
                return ListTile(
                  key: ValueKey('tag-backup-${b.id}'),
                  leading: const Icon(Icons.audio_file_outlined),
                  title: Text(p.basename(b.path), maxLines: 1),
                  subtitle: Text(
                    '${fmt.format(b.createdAt)} • ${formatBytes(b.sizeBytes)}\n${p.dirname(b.path)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => v == 'restore'
                        ? _restore(context, ref, b)
                        : _delete(context, ref, b),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'restore',
                        child: Text(l.tagBackupRestore),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l.tagBackupDelete),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
