import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/duplicate_providers.dart';
import '../../../services/library/duplicate_cleanup.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/format_utils.dart';

/// Deleting the files of merged duplicates takes two confirmations: the first
/// lists every path, the second says how many and how much. Nothing is
/// touched until the second one; backing out of either leaves all as it is.
/// Resolves to the report, or null when the user backed out.
Future<DeleteReport?> confirmAndDeleteMerged(
  BuildContext context,
  WidgetRef ref, {
  FileDeleter? deleter,
}) async {
  final merged = ref.read(duplicateSearchProvider).merged;
  final files = [for (final m in merged) ...m.dropped];
  if (files.isEmpty) return null;
  final bytes = files.fold<int>(0, (n, e) => n + e.sizeBytes);
  final l = context.l10n;

  final listed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.duplicatesDeleteListTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.l10n.duplicatesDeleteListBody),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 8),
              Text(ctx.l10n.duplicatesDeleteAndroidHint),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                key: const ValueKey('delete-paths'),
                shrinkWrap: true,
                children: [
                  for (final f in files)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        f.path,
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.duplicatesDeleteContinue),
        ),
      ],
    ),
  );
  if (listed != true || !context.mounted) return null;

  final sure = await showConfirm(
    context,
    title: l.duplicatesDeleteFinalTitle(files.length),
    body: l.duplicatesDeleteFinalBody(formatBytes(bytes)),
    confirmLabel: l.duplicatesDeleteGo,
    destructive: true,
  );
  if (!sure) return null;

  final report = await ref
      .read(duplicateSearchProvider.notifier)
      .deleteMergedFiles(deleter: deleter);
  if (context.mounted) await _showReport(context, report);
  return report;
}

Future<void> _showReport(BuildContext context, DeleteReport r) {
  final l = context.l10n;
  final cc = context.cc;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.duplicatesDeleteDoneTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.duplicatesDeleteDone(
                r.deleted.length,
                formatBytes(r.freedBytes),
              ),
            ),
            if (r.skipped.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.duplicatesDeleteSkipped(r.skipped.length)),
            ],
            if (r.failed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l.duplicatesDeleteFailed(r.failed.length),
                style: TextStyle(color: cc.error),
              ),
              if (Platform.isAndroid) Text(l.duplicatesDeleteAndroidHint),
              for (final e in r.failed.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${e.key.path}\n${e.value}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.close),
        ),
      ],
    ),
  );
}
