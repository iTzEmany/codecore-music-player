import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../l10n/l10n_ext.dart';

Future<void> scanWithPermission(WidgetRef ref) async {
  final ok = await ensureAudioPermission();
  ref.read(permissionDeniedProvider.notifier).set(!ok);
  if (!ok) return;
  await ref.read(scanStateProvider.notifier).scanAll();
}

Future<void> addFolderAndScan(WidgetRef ref) async {
  final path = await FilePicker.getDirectoryPath();
  if (path == null) return;
  await ref.read(folderRepositoryProvider).add(path);
  await scanWithPermission(ref);
}

class FoldersSheet extends ConsumerWidget {
  const FoldersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider).value ?? const [];
    final scanning = ref.watch(scanStateProvider).running;
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          title: Text(context.l10n.folders),
          trailing: Wrap(children: [
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
          ]),
        ),
        for (final f in folders)
          ListTile(
            leading: const Icon(Icons.folder),
            title: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              tooltip: context.l10n.removeFolder,
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(folderRepositoryProvider).remove(f.id),
            ),
          ),
      ]),
    );
  }
}
