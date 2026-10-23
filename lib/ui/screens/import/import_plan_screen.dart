import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/import_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
import '../../../providers/youtube_providers.dart';
import '../../../services/import/import_candidate.dart';
import '../../../services/online/youtube_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';

/// «Rivedi prima di scaricare»: for each CSV row the video that would be
/// downloaded, with the other candidates to switch to, and one button to go.
class ImportPlanScreen extends ConsumerWidget {
  const ImportPlanScreen({super.key, required this.importId});

  final int importId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final items = ref.watch(importItemsProvider(importId)).value ?? const [];
    final planned = [
      for (final i in items)
        if (i.state == ImportItemStatus.planned) i,
    ];
    final known = ref.watch(downloadIndexProvider).value;
    final svc = ref.read(playlistImportServiceProvider);

    Widget tile(PlaylistImportItem it) {
      final candidates = decodeCandidates(it.candidates);
      final chosen =
          candidates.where((c) => c.id == it.videoId).firstOrNull ??
          (candidates.isEmpty ? null : candidates.first);
      final want = it.durationMs;
      String diffOf(ImportCandidate c) {
        if (want == null || c.durationSec == null) return '';
        final d = c.durationSec! - (want / 1000).round();
        return ' (${d >= 0 ? '+' : ''}$d s)';
      }

      String line(ImportCandidate c) =>
          '${c.source == MediaSource.soundcloud ? '${l.searchSourceSoundcloud}, ' : ''}'
          '${c.channel}, ${formatDuration((c.durationSec ?? 0) * 1000)}'
          '${diffOf(c)}, ${(c.score * 100).round()}%';
      final alreadyHere =
          chosen != null &&
          known?.pathFor(chosen.id, source: chosen.source) != null;
      return ExpansionTile(
        title: Text(
          '${it.title}, ${it.artistList.join(', ')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: chosen == null
            ? null
            : Text(
                '${line(chosen)}${alreadyHere ? ', ${l.csvImportPlanKnown}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      (want != null &&
                          chosen.durationSec != null &&
                          (chosen.durationSec! - want / 1000).abs() > 5)
                      ? cc.error
                      : cc.textMuted,
                ),
              ),
        children: [
          RadioGroup<String>(
            groupValue: chosen?.id,
            onChanged: (id) {
              final c = candidates.where((x) => x.id == id).firstOrNull;
              if (c != null) svc.choosePlanned(importId, it.rowIndex, c);
            },
            child: Column(
              children: [
                for (final c in candidates)
                  RadioListTile<String>(
                    dense: true,
                    value: c.id,
                    title: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${line(c)}${known?.pathFor(c.id, source: c.source) != null ? ', ${l.csvImportPlanKnown}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => svc.skip(importId, it.rowIndex),
              child: Text(l.csvImportSkip),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.csvImportPlanTitle)),
      body: planned.isEmpty
          ? EmptyState(
              icon: Icons.check_circle_outline_rounded,
              message: l.csvImportPlanEmpty,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(children: [for (final it in planned) tile(it)]),
              ),
            ),
      bottomNavigationBar: planned.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(CcDims.margin),
                child: FilledButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await svc.startPlanned(importId);
                    nav.pop();
                  },
                  child: Text(
                    l.csvImportPlanGo(planned.length),
                    style: theme.labelLarge,
                  ),
                ),
              ),
            ),
    );
  }
}
