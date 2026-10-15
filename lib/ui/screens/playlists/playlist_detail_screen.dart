import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../services/covers/cover_store.dart';
import '../../widgets/confirm.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/dismiss_background.dart';
import 'add_tracks_screen.dart';
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

  Future<void> _pickCover(int id) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final res = await FilePicker.pickFiles(type: FileType.image);
    final path = res.isEmpty ? null : res.first.path;
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    if (bytes.length > CoverStore.maxBytes) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.coverTooLarge)));
      return;
    }
    final dir = ref.read(coversDirProvider);
    final store = CoverStore(dir);
    // A new key per pick, so the image cache never shows the old picture.
    final key = await store.saveFromBytes(
      'playlist:$id:${DateTime.now().microsecondsSinceEpoch}',
      bytes,
      path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
    );
    if (key == null) return;
    final old = ref
        .read(playlistsProvider)
        .value
        ?.where((p) => p.playlist.id == id)
        .firstOrNull
        ?.playlist
        .coverKey;
    await ref.read(playlistRepositoryProvider).setCover(id, key);
    if (old != null) await store.fileFor(old)?.delete();
    ref.invalidate(playlistsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = widget.playlist.id;
    final tracks = ref.watch(playlistTracksProvider(id)).value ?? const [];
    final repo = ref.read(playlistRepositoryProvider);
    final cover = ref
        .watch(playlistsProvider)
        .value
        ?.where((p) => p.playlist.id == id)
        .firstOrNull
        ?.coverKey;
    final ctrl = ref.read(playerControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          IconButton(
            tooltip: l.addSongs,
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddTracksScreen(playlistId: id),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'cover':
                  await _pickCover(id);
                case 'clear':
                  await repo.setCover(id, null);
                case 'rename':
                  final n = await askPlaylistName(
                    context,
                    initial: _name,
                    confirmLabel: l.save,
                    title: l.renamePlaylist,
                  );
                  if (n == null) return;
                  await repo.rename(id, n);
                  if (mounted) setState(() => _name = n);
                case 'delete':
                  final ok = await showConfirm(
                    context,
                    title: l.confirmDeletePlaylistTitle,
                    body: l.confirmDeletePlaylistBody(_name),
                    confirmLabel: l.delete,
                    destructive: true,
                  );
                  if (!ok) return;
                  await repo.delete(id);
                  if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'cover', child: Text(l.playlistChangeCover)),
              PopupMenuItem(value: 'clear', child: Text(l.playlistRemoveCover)),
              PopupMenuItem(value: 'rename', child: Text(l.rename)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CoverImage(coverKey: cover, size: 56, radius: 8),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: tracks.isEmpty
                      ? null
                      : () => ctrl.playFromList(
                          tracks,
                          0,
                          context: PlayContext(PlayContextKind.playlist, _name),
                        ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.play),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: tracks.isEmpty
                      ? null
                      : () async {
                          await ctrl.setShuffle(true);
                          await ctrl.playFromList(
                            tracks,
                            0,
                            context: PlayContext(
                              PlayContextKind.playlist,
                              _name,
                            ),
                          );
                        },
                  icon: const Icon(Icons.shuffle),
                  label: Text(l.shuffle),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: tracks.length,
              onReorderItem: (from, to) => repo.reorder(id, from, to),
              itemBuilder: (_, i) {
                final t = tracks[i];
                return Dismissible(
                  key: ValueKey('pl-${t.id}'),
                  background: const DismissBackground(),
                  secondaryBackground: const DismissBackground(alignEnd: true),
                  onDismissed: (_) async {
                    await repo.removeTrack(id, t.id);
                    if (!context.mounted) return;
                    showUndoSnack(context, l.removedFromPlaylist, () async {
                      await repo.addTracks(id, [t.id]);
                      await repo.reorder(id, tracks.length - 1, i);
                    });
                  },
                  child: ListTile(
                    leading: CoverImage(coverKey: t.coverKey, size: 40),
                    title: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(t.artist ?? '', maxLines: 1),
                    onTap: () => ctrl.playFromList(
                      tracks,
                      i,
                      context: PlayContext(PlayContextKind.playlist, _name),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
