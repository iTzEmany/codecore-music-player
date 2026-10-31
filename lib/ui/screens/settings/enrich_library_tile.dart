import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/online_providers.dart';
import '../../widgets/show_msg.dart';

/// «Arricchisci tutta la libreria»: a manual job on the tracks with something
/// due, «nothing» marks included. Off when nothing is due; «Interrompi» while it runs.
class EnrichLibraryTile extends ConsumerWidget {
  const EnrichLibraryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final job = ref.watch(enrichJobProvider);
    final due = ref.watch(manualDueCountProvider).value;
    return ListTile(
      leading: const Icon(Icons.travel_explore),
      title: Text(l.enrichLibrary),
      subtitle: due == null
          ? null
          : Text(due == 0 ? l.enrichLibraryComplete : l.enrichLibraryDue(due, enrichMinutes(due))),
      trailing: job.running
          ? TextButton(
              onPressed: ref.read(enrichJobProvider.notifier).cancel,
              child: Text(l.enrichLibraryStop),
            )
          : null,
      enabled: job.running || (due ?? 0) > 0,
      onTap: job.running
          ? null
          : () async {
              try {
                final r = await ref.read(enrichJobProvider.notifier).startDue();
                if (r == EnrichStart.busy && context.mounted) showMsg(context, l.enrichBusy);
              } on Object catch (e, st) {
                if (e is Error) {
                  AppLog.e('enrich library: not started', e, st);
                } else {
                  AppLog.w('enrich library: not started', e, st);
                }
              }
            },
    );
  }
}
