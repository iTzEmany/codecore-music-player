import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_info.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/update_providers.dart';
import '../../../services/online/update_checker.dart';
import '../../widgets/show_msg.dart';

/// «Controlla aggiornamenti» and «Controlla all'avvio». Nothing while no
/// release repository is configured.
List<Widget> updateTiles(BuildContext context, WidgetRef ref) {
  if (ref.watch(releaseRepoProvider).isEmpty) return const [];
  final l = context.l10n;
  return [
    ListTile(
      leading: const Icon(Icons.system_update_alt_rounded),
      title: Text(l.updateCheck),
      subtitle: Text(l.updateCheckHint),
      onTap: () => showDialog<void>(context: context, builder: (_) => const UpdateDialog()),
    ),
    SwitchListTile(
      title: Text(l.updateOnStart),
      subtitle: Text(l.updateOnStartHint),
      value: ref.watch(checkUpdatesOnStartProvider),
      onChanged: ref.read(checkUpdatesOnStartProvider.notifier).set,
    ),
  ];
}

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  late final Future<UpdateResult> _result =
      ref.read(updateCheckerProvider)?.check() ?? Future.value(const UpdateResult(UpdateStatus.failed));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.updateCheck),
      content: FutureBuilder<UpdateResult>(
        future: _result,
        builder: (context, snap) {
          final r = snap.data;
          if (r == null) {
            return Row(children: [
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 16),
              Text(l.updateChecking),
            ]);
          }
          final info = r.info;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(switch (r.status) {
                  UpdateStatus.newer => l.updateAvailable(info!.version),
                  UpdateStatus.upToDate => l.updateUpToDate(kAppVersion),
                  UpdateStatus.rateLimited => l.updateRateLimited,
                  UpdateStatus.failed => l.updateFailed,
                }),
                if (r.status == UpdateStatus.newer && info != null) ...[
                  if (info.notes.isNotEmpty) ...[const SizedBox(height: 12), Text(info.notes)],
                  const SizedBox(height: 12),
                  SelectableText(info.url, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        FutureBuilder<UpdateResult>(
          future: _result,
          builder: (context, snap) {
            final info = snap.data?.status == UpdateStatus.newer ? snap.data!.info : null;
            if (info == null) return const SizedBox.shrink();
            return TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: info.url));
                if (!context.mounted) return;
                showMsg(context, l.updateLinkCopied);
              },
              child: Text(l.updateCopyLink),
            );
          },
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.close)),
      ],
    );
  }
}
