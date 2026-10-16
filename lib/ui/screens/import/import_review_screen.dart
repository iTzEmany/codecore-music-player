import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/import_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
import '../../../services/import/import_candidate.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';
import 'import_manual_search_sheet.dart';

/// Rows of an import that need the user: unsure matches (with candidates),
/// nothing found and errors.
class ImportReviewScreen extends ConsumerWidget {
  const ImportReviewScreen({super.key, required this.importId});

  final int importId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final items = ref.watch(importItemsProvider(importId)).value ?? const [];
    final svc = ref.read(playlistImportServiceProvider);
    List<PlaylistImportItem> of(ImportItemStatus s) =>
        [for (final i in items) if (i.state == s) i];
    final review = of(ImportItemStatus.review);
    final missing = of(ImportItemStatus.notFound);
    final failed = of(ImportItemStatus.failed);

    Widget wanted(PlaylistImportItem it) => Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 12, CcDims.margin, 4),
      child: Text(
        l.csvImportWanted(
          it.title,
          it.artistList.join(', '),
          formatDuration(it.durationMs ?? 0),
        ),
        style: theme.titleSmall,
      ),
    );

    Widget lengthNote(PlaylistImportItem it) => Consumer(
      builder: (context, ref, _) {
        final t = ref.watch(importedTrackProvider(it.trackId!)).value;
        if (t == null) return const SizedBox.shrink();
        return ListTile(
          dense: true,
          leading: Icon(Icons.warning_amber_rounded, color: cc.error),
          title: Text(l.csvImportLengthOff(
            formatDuration(t.durationMs),
            formatDuration(it.durationMs ?? 0),
          )),
          trailing: TextButton(
            onPressed: () => svc.keepDownloaded(importId, it.rowIndex),
            child: Text(l.csvImportKeep),
          ),
        );
      },
    );

    Widget actions(PlaylistImportItem it) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          TextButton(
            onPressed: () => ImportManualSearchSheet.show(
              context,
              importId: importId,
              row: it.toRow(),
            ),
            child: Text(l.csvImportManual),
          ),
          TextButton(
            onPressed: () => svc.skip(importId, it.rowIndex),
            child: Text(l.csvImportSkip),
          ),
        ],
      ),
    );

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 20, CcDims.margin, 0),
      child: Text(text, style: theme.labelLarge?.copyWith(color: cc.textMuted)),
    );

    Widget candidate(PlaylistImportItem it, ImportCandidate c) {
      final want = it.durationMs;
      final diff = (want == null || c.durationSec == null)
          ? null
          : c.durationSec! - (want / 1000).round();
      return ListTile(
        dense: true,
        title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${c.channel} · ${formatDuration((c.durationSec ?? 0) * 1000)}'
          '${diff == null ? '' : ' (${diff >= 0 ? '+' : ''}$diff s)'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: diff != null && diff.abs() > 5 ? cc.error : cc.textMuted,
          ),
        ),
        trailing: IconButton(
          tooltip: l.csvImportDownload,
          icon: const Icon(Icons.download_rounded),
          onPressed: () => svc.download(importId, it.rowIndex, c.toYtResult()),
        ),
        onTap: () => svc.download(importId, it.rowIndex, c.toYtResult()),
      );
    }

    final empty = review.isEmpty && missing.isEmpty && failed.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.csvImportReviewTitle),
        actions: [
          if (missing.isNotEmpty || failed.isNotEmpty)
            TextButton(
              onPressed: () => svc.retry(importId),
              child: Text(l.csvImportRetryAll),
            ),
        ],
      ),
      body: empty
          ? EmptyState(
              icon: Icons.check_circle_outline_rounded,
              message: l.csvImportNothing,
            )
          : ListView(
              children: [
                if (review.isNotEmpty) header(l.csvImportToReview),
                for (final it in review) ...[
                  wanted(it),
                  if (it.trackId != null) lengthNote(it),
                  for (final c in decodeCandidates(it.candidates))
                    candidate(it, c),
                  actions(it),
                ],
                if (missing.isNotEmpty) header(l.csvImportNotFound),
                for (final it in missing) ...[wanted(it), actions(it)],
                if (failed.isNotEmpty) header(l.csvImportErrors),
                for (final it in failed) ...[wanted(it), actions(it)],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
