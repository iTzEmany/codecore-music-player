import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/import_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import 'import_review_screen.dart';

/// Top of a playlist page while its CSV import is running or has rows that
/// need the user. Hidden once everything is resolved.
class ImportBanner extends ConsumerWidget {
  const ImportBanner({super.key, required this.playlistId});

  final int playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(playlistImportProgressProvider(playlistId));
    final running = ref.watch(importProgressProvider).any((i) => i.playlistId == playlistId);
    if (p == null || (!running && p.review == 0 && p.missing == 0)) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    final cc = context.cc;
    final text = p.paused
        ? l.csvImportBannerPaused(p.done, p.total, p.review, p.missing)
        : l.csvImportBanner(p.done, p.total, p.review, p.missing);
    final svc = ref.read(playlistImportServiceProvider);
    return Container(
      margin: const EdgeInsets.fromLTRB(CcDims.margin, 8, CcDims.margin, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: cc.surface2,
        borderRadius: BorderRadius.circular(CcDims.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ),
              if (p.paused)
                TextButton(
                  onPressed: () => svc.resume(p.id),
                  child: Text(l.csvImportResume),
                ),
              if (p.review + p.missing > 0)
                TextButton(
                  onPressed: () => ShellNav.open<void>(
                    context,
                    ImportReviewScreen(importId: p.id),
                  ),
                  child: Text(l.csvImportReview),
                ),
            ],
          ),
          if (running && !p.paused)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: LinearProgressIndicator(value: p.fraction),
            ),
        ],
      ),
    );
  }
}
