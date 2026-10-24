import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/exportify_providers.dart';
import '../../theme/tokens.dart';
import '../import/import_flow.dart';

/// In Home: the Exportify file found in Downloads (desktop), else the
/// reminder to sync with Spotify when it is due.
class ExportifyCard extends ConsumerWidget {
  const ExportifyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final found = ref.watch(exportifyDownloadProvider);
    final due = ref.watch(exportifyReminderProvider).value ?? false;
    if (found == null && !due) return const SizedBox.shrink();
    final cc = context.cc;
    final reminder = ref.read(exportifyReminderProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CcDims.margin,
        CcDims.gap8,
        CcDims.margin,
        0,
      ),
      child: Container(
        key: const ValueKey('exportify-card'),
        padding: const EdgeInsets.only(top: CcDims.gap8),
        decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: cc.separator)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sync_rounded, color: cc.accentSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    found != null
                        ? l.exportifyFoundTitle
                        : l.exportifyCardTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (found == null)
                    TextButton(
                      key: const ValueKey('exportify-later'),
                      onPressed: reminder.snooze,
                      child: Text(l.exportifyCardLater),
                    ),
                  TextButton(
                    key: const ValueKey('exportify-go'),
                    onPressed: () async {
                      if (found != null) {
                        await ref
                            .read(exportifyDownloadProvider.notifier)
                            .consume();
                        if (context.mounted) {
                          await openImportFile(context, ref, found.path);
                        }
                      } else {
                        await reminder.snooze();
                        await openExportify(ref);
                      }
                    },
                    child: Text(
                      found != null
                          ? l.exportifyFoundSync
                          : l.exportifyCardOpen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
