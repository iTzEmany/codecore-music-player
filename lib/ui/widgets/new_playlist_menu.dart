import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../screens/import/import_flow.dart';
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
    return PopupMenuButton<_NewPlaylistAction>(
      tooltip: l.newPlaylist,
      icon: const Icon(Icons.add_rounded),
      onSelected: (v) async {
        switch (v) {
          case _NewPlaylistAction.csv:
            startCsvImport(context, ref);
          case _NewPlaylistAction.smart:
            onSmart();
          case _NewPlaylistAction.create:
            await createPlaylistFlow(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _NewPlaylistAction.create,
          child: Text(l.newPlaylist),
        ),
        PopupMenuItem(
          value: _NewPlaylistAction.smart,
          child: Text(l.smartPlaylistNew),
        ),
        PopupMenuItem(
          value: _NewPlaylistAction.csv,
          child: Text(l.csvImportMenu),
        ),
      ],
    );
  }
}
