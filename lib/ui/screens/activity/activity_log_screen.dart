import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/activity_log_providers.dart';
import '../../../providers/activity_providers.dart';
import '../../../services/import/playlist_import_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import 'activity_sheet.dart';

/// What ended in the background (downloads, transfers, imports), newest
/// first, with the time and how it went.
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  String _outcome(AppLocalizations l, LogEntry e) => switch (e.event) {
        null => e.failed ? l.offerFailed : l.offerDone,
        ImportEventKind.completed => l.offerDone,
        ImportEventKind.planned => l.csvImportPlanned,
        ImportEventKind.rateLimited => l.ytErrRateLimited,
        ImportEventKind.network => l.ytErrNetwork,
        ImportEventKind.toolMissing => l.ytErrToolMissing,
        ImportEventKind.toolOutdated => l.ytErrToolOutdated,
        ImportEventKind.failing => l.csvImportFailing,
      };

  IconData _icon(LogEntry e) {
    if (e.failed) return Icons.error_outline_rounded;
    return switch (e.item?.kind) {
      ActivityKind.transfer => Icons.send_rounded,
      null => Icons.playlist_add_check_rounded,
      _ => Icons.download_done_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final entries = ref.watch(activityLogProvider);
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    return Scaffold(
      appBar: AppBar(
        title: Text(l.activityLog),
        actions: [
          if (entries.isNotEmpty)
            TextButton(
              onPressed: ref.read(activityLogProvider.notifier).clear,
              child: Text(l.activityClear),
            ),
        ],
      ),
      body: entries.isEmpty
          ? EmptyState(icon: Icons.receipt_long_rounded, message: l.activityLogEmpty)
          : ListView.builder(
              itemExtent: 64,
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i];
                final item = e.item;
                return ListTile(
                  leading: Icon(_icon(e), color: e.failed ? cc.error : cc.accentSoft),
                  title: Text(
                    item != null ? activityTitle(l, item) : l.logImport(e.importName ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${time.format(e.at)}, ${_outcome(l, e)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium?.copyWith(color: e.failed ? cc.error : null),
                  ),
                );
              },
            ),
    );
  }
}
