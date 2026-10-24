import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_providers.dart';
import '../../../providers/folder_actions.dart';
import '../../../providers/library_providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';

/// Asks before dropping a folder (its tracks leave the library).
Future<void> confirmRemoveFolder(
  BuildContext context,
  WidgetRef ref,
  int folderId,
) async {
  final l = context.l10n;
  final ok = await showConfirm(
    context,
    title: l.confirmRemoveFolderTitle,
    body: l.confirmRemoveFolderBody,
    confirmLabel: l.removeFolder,
    destructive: true,
  );
  if (ok) await ref.read(folderRepositoryProvider).remove(folderId);
}

class FoldersSheet extends ConsumerWidget {
  const FoldersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider).value ?? const [];
    final scanning = ref.watch(scanStateProvider).running;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(CcDims.margin, CcDims.gap4, CcDims.gap4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.folders,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.refreshLibrary,
                  onPressed: scanning ? null : () => scanWithPermission(ref),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: context.l10n.addFolder,
                  onPressed: () => addFolderAndScan(ref),
                  icon: const Icon(Icons.create_new_folder),
                ),
              ],
            ),
          ),
          for (final f in folders)
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: context.l10n.removeFolder,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => confirmRemoveFolder(context, ref, f.id),
              ),
            ),
        ],
      ),
    );
  }
}
