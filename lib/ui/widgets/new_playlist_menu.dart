import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../screens/import/import_flow.dart';
import 'cc_sheet.dart';
import 'create_flows.dart';

enum _NewPlaylistAction { create, smart, csv }

/// The «+» menu: new playlist, new smart playlist, CSV import. How the smart
/// editor opens depends on the caller ([onSmart]).
class NewPlaylistMenu extends ConsumerWidget {
  const NewPlaylistMenu({super.key, required this.onSmart});

  final VoidCallback onSmart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return IconButton(
      tooltip: l.newPlaylist,
      icon: const Icon(Icons.add_rounded),
      onPressed: () async {
        final v = await showCcActionSheet<_NewPlaylistAction>(
          context: context,
          groups: [
            [
              CcAction(
                icon: Icons.playlist_add_rounded,
                label: l.newPlaylist,
                value: _NewPlaylistAction.create,
              ),
              CcAction(
                icon: Icons.auto_awesome_rounded,
                label: l.smartPlaylistNew,
                value: _NewPlaylistAction.smart,
              ),
              CcAction(
                icon: Icons.upload_file_rounded,
                label: l.csvImportMenu,
                value: _NewPlaylistAction.csv,
              ),
            ],
          ],
        );
        if (v == null || !context.mounted) return;
        switch (v) {
          case _NewPlaylistAction.csv:
            startCsvImport(context, ref);
          case _NewPlaylistAction.smart:
            onSmart();
          case _NewPlaylistAction.create:
            await createPlaylistFlow(context, ref);
        }
      },
    );
  }
}
