import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/online_providers.dart';

/// Shows the outcome of an enrichment batch once, as a snackbar. The running
/// progress lives in the Activity centre.
class EnrichResultListener extends ConsumerWidget {
  const EnrichResultListener({super.key});

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
    return const SizedBox.shrink();
  }
}
