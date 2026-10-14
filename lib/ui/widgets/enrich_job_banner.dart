import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/online_providers.dart';

/// Progress strip with Cancel while an enrichment batch runs; reports the
/// result with a snackbar when it ends.
class EnrichJobBanner extends ConsumerWidget {
  const EnrichJobBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.listen(enrichJobProvider, (_, next) {
      final r = next.result;
      if (r == null) return;
      final text = r.rateLimited
          ? l.serviceUnavailable
          : l.enrichResult(r.updated, r.notFound);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(text)));
      ref.read(enrichJobProvider.notifier).clearResult();
    });
    final job = ref.watch(enrichJobProvider);
    if (!job.running) return const SizedBox.shrink();
    final p = job.progress;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.enrichRunning(p?.done ?? 0, p?.total ?? 0)),
                LinearProgressIndicator(
                    value: (p == null || p.total == 0) ? null : p.done / p.total),
              ],
            ),
          ),
          TextButton(
              onPressed: ref.read(enrichJobProvider.notifier).cancel,
              child: Text(l.cancel)),
        ]),
      ),
    );
  }
}
