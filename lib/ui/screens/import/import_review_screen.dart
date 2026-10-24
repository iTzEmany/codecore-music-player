import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/import_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
import '../../../services/export/save_file.dart';
import '../../../services/import/import_candidate.dart';
import '../../../services/online/youtube_service.dart';
import '../../../services/import/import_outcome.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/section_header.dart';
import 'import_labels.dart';
import 'import_manual_search_sheet.dart';
import '../../widgets/show_msg.dart';
import '../../widgets/cc_app_bar.dart';

/// Rows of an import that need the user: unsure matches (with candidates),
/// nothing found and errors.
class ImportReviewScreen extends ConsumerWidget {
  const ImportReviewScreen({super.key, required this.importId});

  final int importId;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(importItemsProvider(importId)).value ?? const [];
    final svc = ref.read(playlistImportServiceProvider);
    List<PlaylistImportItem> of(ImportItemStatus s) => [
      for (final i in items)
        if (i.state == s) i,
    ];
    final review = of(ImportItemStatus.review);
    final missing = of(ImportItemStatus.notFound);
    final failed = of(ImportItemStatus.failed);

    final empty = review.isEmpty && missing.isEmpty && failed.isEmpty;
    return Scaffold(
      appBar: CcAppBar(
        title: l.csvImportReviewTitle,
        actions: [
          IconButton(
            tooltip: l.csvImportExport,
            icon: const Icon(Icons.download_outlined),
            onPressed: items.isEmpty ? null : () => _exportOutcome(context, items),
          ),
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
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(
                  children: [
                    if (review.isNotEmpty) SectionHeader(l.csvImportToReview),
                    for (final it in review) ...[
                      _Wanted(it),
                      if (it.trackId != null) _LengthNote(importId, it),
                      for (final c in decodeCandidates(it.candidates))
                        _Candidate(importId, it, c),
                      _RowActions(importId, it),
                    ],
                    if (missing.isNotEmpty) SectionHeader(l.csvImportNotFound),
                    for (final it in missing) ...[
                      _Wanted(it),
                      _RowActions(importId, it),
                    ],
                    if (failed.isNotEmpty) SectionHeader(l.csvImportErrors),
                    for (final it in failed) ...[
                      _Wanted(it),
                      _RowActions(importId, it),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

Future<void> _exportOutcome(
  BuildContext context,
  List<PlaylistImportItem> items,
) async {
  final l = context.l10n;
  final csv = importOutcomeCsv(
    items,
    status: (s) => importStatusLabel(l, s),
    note: (c) => importNoteLabel(l, c),
    header: [
      l.csvOutHeaderRow,
      l.csvOutHeaderTitle,
      l.csvOutHeaderArtists,
      l.csvOutHeaderAlbum,
      l.csvOutHeaderDuration,
      l.csvOutHeaderIsrc,
      l.csvOutHeaderStatus,
      l.csvOutHeaderNote,
      l.csvOutHeaderVideo,
      l.csvOutHeaderScore,
    ],
  );
  final saved = await saveBytes(
    'import-result.csv',
    Uint8List.fromList(utf8.encode('\uFEFF$csv')),
    mimeType: 'text/csv',
  );
  if (saved) {
    if (!context.mounted) return;
    showMsg(context, l.csvImportExported);
  }
}

class _Wanted extends StatelessWidget {
  const _Wanted(this.it);

  final PlaylistImportItem it;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, CcDims.gap12, CcDims.margin, CcDims.gap4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.csvImportWanted(
              it.title,
              it.artistList.join(', '),
              formatDuration(it.durationMs ?? 0),
            ),
            style: theme.titleSmall,
          ),
          if (it.note != null)
            Text(
              importNoteLabel(l, it.note!),
              style: theme.bodySmall?.copyWith(color: cc.textMuted),
            ),
        ],
      ),
    );
  }
}

class _LengthNote extends ConsumerWidget {
  const _LengthNote(this.importId, this.it);

  final int importId;
  final PlaylistImportItem it;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = ref.watch(importedTrackProvider(it.trackId!)).value;
    if (t == null) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: Icon(Icons.warning_amber_rounded, color: context.cc.error),
      title: Text(
        l.csvImportLengthOff(
          formatDuration(t.durationMs),
          formatDuration(it.durationMs ?? 0),
        ),
      ),
      trailing: TextButton(
        onPressed: () => ref
            .read(playlistImportServiceProvider)
            .keepDownloaded(importId, it.rowIndex),
        child: Text(l.csvImportKeep),
      ),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions(this.importId, this.it);

  final int importId;
  final PlaylistImportItem it;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CcDims.gap8),
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
            onPressed: () =>
                ref.read(playlistImportServiceProvider).skip(importId, it.rowIndex),
            child: Text(l.csvImportSkip),
          ),
        ],
      ),
    );
  }
}

class _Candidate extends ConsumerWidget {
  const _Candidate(this.importId, this.it, this.c);

  final int importId;
  final PlaylistImportItem it;
  final ImportCandidate c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    void download() => ref
        .read(playlistImportServiceProvider)
        .download(importId, it.rowIndex, c.toYtResult());
    final want = it.durationMs;
    final diff = (want == null || c.durationSec == null)
        ? null
        : c.durationSec! - (want / 1000).round();
    return ListTile(
      dense: true,
      title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${c.source == MediaSource.soundcloud ? '${l.searchSourceSoundcloud}, ' : ''}'
        '${c.channel}, ${formatDuration((c.durationSec ?? 0) * 1000)}'
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
        onPressed: download,
      ),
      onTap: download,
    );
  }
}
