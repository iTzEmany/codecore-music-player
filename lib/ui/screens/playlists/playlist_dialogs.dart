import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';

/// Asks for a playlist name (1..60 chars). Returns null when cancelled.
Future<String?> askPlaylistName(BuildContext context,
    {String initial = '', String? confirmLabel}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(initial: initial, confirmLabel: confirmLabel),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial, this.confirmLabel});

  final String initial;
  final String? confirmLabel;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _c.text.trim();
    if (t.isNotEmpty) Navigator.of(context).pop(t);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.newPlaylist),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(hintText: l.playlistName),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel)),
        FilledButton(
            onPressed: _submit, child: Text(widget.confirmLabel ?? l.create)),
      ],
    );
  }
}

/// Bottom sheet to add tracks to an existing or a new playlist.
Future<void> showAddToPlaylistSheet(
    BuildContext context, WidgetRef ref, List<Track> tracks) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _AddToPlaylistSheet(tracks: tracks, outer: context),
  );
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.tracks, required this.outer});

  final List<Track> tracks;
  final BuildContext outer;

  Future<void> _add(WidgetRef ref, BuildContext sheetContext, int id,
      String name) async {
    final repo = ref.read(playlistRepositoryProvider);
    await repo.addTracks(id, [for (final t in tracks) t.id]);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (outer.mounted) {
      ScaffoldMessenger.of(outer)
        ..clearSnackBars()
        ..showSnackBar(
            SnackBar(content: Text(outer.l10n.addedToPlaylist(name))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lists = ref.watch(playlistsProvider).value ?? const [];
    return SafeArea(
      child: ListView(shrinkWrap: true, children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l.newPlaylistEllipsis),
          onTap: () async {
            final name = await askPlaylistName(context);
            if (name == null || !context.mounted) return;
            final id = await ref.read(playlistRepositoryProvider).create(name);
            if (!context.mounted) return;
            await _add(ref, context, id, name);
          },
        ),
        for (final p in lists)
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(p.playlist.name),
            onTap: () => _add(ref, context, p.playlist.id, p.playlist.name),
          ),
      ]),
    );
  }
}
