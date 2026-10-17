import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../widgets/confirm.dart';

/// «Sposta in un nuovo album…» for a selection of tracks: asks the album's
/// title and artist (the common ones are suggested) and moves them there; a
/// name that already exists merges with it. Library only, with an undo.
/// Resolves to true when it moved something.
Future<bool> showMoveToAlbumDialog(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks,
) async {
  if (tracks.isEmpty) return false;
  final l = context.l10n;
  final res = await showDialog<(String, String)>(
    context: context,
    builder: (_) => _MoveDialog(tracks: tracks),
  );
  if (res == null || !context.mounted) return false;
  final editor = ref.read(trackEditorProvider);
  final before = await editor.saveMany(
    tracks,
    album: res.$1,
    albumArtist: res.$2,
  );
  if (context.mounted) {
    showUndoSnack(
      context,
      l.movedToAlbum(tracks.length, res.$1),
      () => editor.restoreMany(before),
    );
  }
  return true;
}

/// The value all [values] share, or '' if they differ or are blank.
String _common(Iterable<String?> values) {
  final set = {for (final v in values) (v ?? '').trim()};
  return set.length == 1 ? set.single : '';
}

class _MoveDialog extends StatefulWidget {
  const _MoveDialog({required this.tracks});

  final List<Track> tracks;

  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog> {
  late final _title = TextEditingController(
    text: _common(widget.tracks.map((t) => t.album)),
  );
  late final _artist = TextEditingController(
    text: _common(widget.tracks.map((t) => t.albumArtist ?? t.artist)),
  );

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    super.dispose();
  }

  bool get _ok =>
      _title.text.trim().isNotEmpty && _artist.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.moveToAlbumTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.moveToAlbumBody(widget.tracks.length)),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('move-title'),
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(labelText: l.albumFieldTitle),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              key: const ValueKey('move-artist'),
              controller: _artist,
              decoration: InputDecoration(labelText: l.albumFieldArtist),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('move-go'),
          onPressed: _ok
              ? () => Navigator.pop(context, (
                  _title.text.trim(),
                  _artist.text.trim(),
                ))
              : null,
          child: Text(l.moveToAlbumGo),
        ),
      ],
    );
  }
}
