import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/tag_backup_providers.dart';
import '../cleanup/tag_backups_screen.dart';
import '../../widgets/confirm.dart';

/// «Write edits into the files» (with its warning) and «Tag backups».
List<Widget> tagWriteTiles(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final on = ref.watch(settingsProvider.select((s) => s.writeTagsToFiles));
  final count = ref.watch(tagBackupsProvider).value?.length ?? 0;
  Future<void> toggle(bool v) async {
    if (v) {
      final ok = await showConfirm(
        context,
        title: l.writeTagsWarnTitle,
        body: l.writeTagsWarnBody,
        confirmLabel: l.writeTagsEnable,
      );
      if (!ok) return;
    }
    ref
        .read(settingsProvider.notifier)
        .update((c) => c.copyWith(writeTagsToFiles: v));
  }

  return [
    SwitchListTile(
      secondary: const Icon(Icons.edit_note_rounded),
      title: Text(l.writeTagsToFiles),
      subtitle: Text(l.writeTagsToFilesHint),
      value: on,
      onChanged: toggle,
    ),
    ListTile(
      leading: const Icon(Icons.history_rounded),
      title: Text(l.tagBackupsCount(count)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TagBackupsScreen()),
      ),
    ),
  ];
}
