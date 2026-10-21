import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/import_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../services/import/import_row_phase.dart';
import '../../../services/online/download_queue.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/format_utils.dart';
import 'import_labels.dart';
import 'import_review_screen.dart';

enum _Filter { all, active, problems, done }

/// One import, all its songs in one list (also when it was made «a blocchi»),
/// each with the phase it is in: waiting, searching, downloading, tags and
/// cover, done, or what went wrong.
class ImportDetailScreen extends ConsumerStatefulWidget {
  const ImportDetailScreen({super.key, required this.importId});

  /// Any block of the import.
  final int importId;

  @override
  ConsumerState<ImportDetailScreen> createState() => _ImportDetailScreenState();
}

class _ImportDetailScreenState extends ConsumerState<ImportDetailScreen> {
  _Filter _filter = _Filter.all;

  bool _shows(RowPhase p) => switch (_filter) {
        _Filter.all => true,
        _Filter.active => p.active,
        _Filter.problems => p.problem,
        _Filter.done => p.settled,
      };

  Future<void> _cancel(int id) async {
    final l = context.l10n;
    final ok = await showConfirm(
      context,
      title: l.csvImportCancelTitle,
      body: l.csvImportCancelBody,
      confirmLabel: l.csvImportCancelGo,
      destructive: true,
    );
    if (ok) await ref.read(playlistImportServiceProvider).cancelChain(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final p = ref.watch(importChainProgressProvider(widget.importId));
    final items = ref.watch(importChainItemsProvider(widget.importId)) ?? const <PlaylistImportItem>[];
    final steps = ref.watch(importStepsProvider).value ?? const {};
    final enriching = ref.watch(enrichingTracksProvider).value ?? const {};
    final downloads = ref.watch(importDownloadsProvider);
    final wait = ref.watch(importWaitProvider).value;
    final rows = [
      for (final i in items)
        if (i.state != ImportItemStatus.removed)
          (item: i, download: downloads[(i.importId, i.rowIndex)]),
    ];
    final phases = [for (final r in rows) rowPhase(r.item, steps: steps, enriching: enriching, download: r.download)];
    int count(bool Function(RowPhase) test) => phases.where(test).length;
    final shown = [
      for (var i = 0; i < rows.length; i++)
        if (_shows(phases[i])) (row: rows[i], phase: phases[i]),
    ];
    final svc = ref.read(playlistImportServiceProvider);
    final unfinished = p != null && p.done < p.total;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (p != null && unfinished)
            IconButton(
              tooltip: p.paused ? l.csvImportResume : l.csvImportPause,
              icon: Icon(p.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              onPressed: () => p.paused ? svc.resumeChain(p.id) : svc.pauseChain(p.id),
            ),
          if (p != null && unfinished)
            IconButton(
              tooltip: l.cancel,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _cancel(p.id),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, CcDims.margin, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: p.fraction),
                  const SizedBox(height: 8),
                  Text(
                    (p.paused
                            ? l.csvImportBannerPaused(p.done, p.total, p.review, p.missing)
                            : l.csvImportBanner(p.done, p.total, p.review, p.missing)) +
                        (p.eta == null ? '' : ' · ${etaLabel(l, p.eta!)}'),
                    style: theme.bodyMedium?.copyWith(color: cc.textMuted),
                  ),
                  if (wait != null && !p.paused)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        importWaitLabel(l, wait),
                        style: theme.bodyMedium?.copyWith(color: cc.accentSoft),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
              children: [
                for (final (f, label, n) in [
                  (_Filter.all, l.importFilterAll, rows.length),
                  (_Filter.active, l.importFilterActive, count((p) => p.active)),
                  (_Filter.problems, l.importFilterProblems, count((p) => p.problem)),
                  (_Filter.done, l.importFilterDone, count((p) => p.settled)),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$label · $n'),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text(l.importRowsNone, style: theme.bodyMedium))
                : ListView.builder(
                    itemExtent: 64,
                    itemCount: shown.length,
                    itemBuilder: (_, i) => _SongRow(
                      item: shown[i].row.item,
                      phase: shown[i].phase,
                      download: shown[i].row.download,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({required this.item, required this.phase, required this.download});

  final PlaylistImportItem item;
  final RowPhase phase;
  final DownloadItem? download;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final color = phase.problem
        ? cc.error
        : phase.active
            ? cc.accentSoft
            : cc.textMuted;
    final Widget leading = phase.active
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              // Before the first bytes the size is unknown: no empty ring.
              value: phase == RowPhase.downloading && (download?.progress ?? 0) > 0
                  ? download!.progress
                  : null,
            ),
          )
        : Icon(
            switch (phase) {
              RowPhase.downloaded || RowPhase.linked => Icons.check_circle_rounded,
              RowPhase.review => Icons.help_outline_rounded,
              RowPhase.notFound || RowPhase.failed => Icons.error_outline_rounded,
              RowPhase.skipped || RowPhase.removed => Icons.remove_circle_outline_rounded,
              _ => Icons.schedule_rounded,
            },
            color: color,
            size: 22,
          );
    return InkWell(
      // A song that needs the user opens the review of its block.
      onTap: phase.problem
          ? () => ShellNav.open<void>(context, ImportReviewScreen(importId: item.importId))
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
        child: Row(
          children: [
            SizedBox(width: 28, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.bodyLarge),
                  Text(
                    '${item.artistList.join(', ')} · ${rowPhaseLabel(l, phase, download)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyMedium?.copyWith(color: phase.active || phase.problem ? color : null),
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
