import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/enrich_completer_providers.dart';

/// «Completa l'arricchimento»: fills what the library lacks now, without the
/// pauses of the background completion; «Interrompi» stops it.
class EnrichCompleteTile extends ConsumerWidget {
  const EnrichCompleteTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = ref.watch(enrichCompleterProvider);
    final notifier = ref.read(enrichCompleterProvider.notifier);
    final going = c.running && c.manual;
    return ListTile(
      leading: const Icon(Icons.auto_fix_high_rounded),
      title: Text(l.enrichCompleteTitle),
      subtitle: Text(
        going ? l.enrichCompleteProgress(c.complete, c.total) : l.enrichCompleteHint,
      ),
      trailing: going
          ? TextButton(onPressed: notifier.cancel, child: Text(l.enrichCompleteStop))
          : null,
      onTap: going ? null : notifier.runNow,
    );
  }
}
