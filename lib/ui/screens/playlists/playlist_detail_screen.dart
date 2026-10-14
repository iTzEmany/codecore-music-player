import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/player_providers.dart';
import '../../widgets/cover_image.dart';
import 'playlist_dialogs.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});

  final Playlist playlist;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  late String _name = widget.playlist.name;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = widget.playlist.id;
    final tracks = ref.watch(playlistTracksProvider(id)).value ?? const [];
    final repo = ref.read(playlistRepositoryProvider);
    final ctrl = ref.read(playerControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          IconButton(
            tooltip: l.rename,
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final n = await askPlaylistName(context,
                  initial: _name, confirmLabel: l.save);
              if (n == null) return;
              await repo.rename(id, n);
              if (mounted) setState(() => _name = n);
            },
          ),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await repo.delete(id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            FilledButton.icon(
              onPressed:
                  tracks.isEmpty ? null : () => ctrl.playFromList(tracks, 0),
              icon: const Icon(Icons.play_arrow),
              label: Text(l.play),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: tracks.isEmpty
                  ? null
                  : () async {
                      await ctrl.setShuffle(true);
                      await ctrl.playFromList(tracks, 0);
                    },
              icon: const Icon(Icons.shuffle),
              label: Text(l.shuffle),
            ),
          ]),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: tracks.length,
            onReorderItem: (from, to) => repo.reorder(id, from, to),
            itemBuilder: (_, i) {
              final t = tracks[i];
              return Dismissible(
                key: ValueKey('pl-${t.id}'),
                onDismissed: (_) => repo.removeTrack(id, t.id),
                child: ListTile(
                  leading: CoverImage(coverKey: t.coverKey, size: 40),
                  title: Text(t.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(t.artist ?? '', maxLines: 1),
                  onTap: () => ctrl.playFromList(tracks, i),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
