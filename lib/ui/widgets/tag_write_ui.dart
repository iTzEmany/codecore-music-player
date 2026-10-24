import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/settings_providers.dart';
import '../../providers/tag_backup_providers.dart';
import '../../services/library/track_file_sync.dart';
import '../../services/tags/tag_writer.dart';
import 'show_msg.dart';

String tagReasonText(AppLocalizations l, TagWriteReason r) => switch (r) {
  TagWriteReason.unsupported => l.tagReasonUnsupported,
  TagWriteReason.notFound => l.tagReasonNotFound,
  TagWriteReason.readOnly => l.tagReasonReadOnly,
  TagWriteReason.verifyFailed => l.tagReasonVerifyFailed,
  TagWriteReason.writeFailed => l.tagReasonWriteFailed,
  TagWriteReason.backupFailed => l.tagReasonBackupFailed,
  TagWriteReason.ioError => l.tagReasonIoError,
};

/// A warning (not an error): the library edit is saved; some files were not.
void showTagFileOutcome(
  ScaffoldMessengerState messenger,
  AppLocalizations l,
  TagFileOutcome outcome,
) {
  final reason = outcome.mainReason;
  if (reason == null) return;
  showMsgOn(
    messenger,
    l.tagsFileWriteFailed(outcome.failures.length, tagReasonText(l, reason)),
  );
}

/// «Also write to the file» checkbox of the edit dialogs. Hidden when the
/// option is off; with a [path] it is disabled (with the reason) for a file
/// that cannot be rewritten. The answer is remembered in the settings.
class AlsoInFileTile extends ConsumerWidget {
  const AlsoInFileTile({super.key, this.path});

  final String? path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    if (!s.writeTagsToFiles) return const SizedBox.shrink();
    final l = context.l10n;
    final why = path == null
        ? null
        : ref.watch(tagWritableProvider(path!)).value;
    final blocked = switch (why) {
      null => null,
      TagWriteReason.unsupported => l.tagsNoWriteUnsupported(
        tagFormatOf(path!).toUpperCase(),
      ),
      TagWriteReason.notFound => l.tagsNoWriteMissing,
      _ => l.tagsNoWriteReadOnly,
    };
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(l.tagsAlsoInFile),
      subtitle: blocked == null ? null : Text(blocked),
      value: blocked == null && s.tagsAlsoInFile,
      onChanged: blocked == null
          ? (v) => ref
                .read(settingsProvider.notifier)
                .update((c) => c.copyWith(tagsAlsoInFile: v ?? false))
          : null,
    );
  }
}
