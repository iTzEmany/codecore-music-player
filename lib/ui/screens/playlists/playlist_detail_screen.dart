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
import '../../../providers/selection_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/collection_header.dart';
import '../../shell/shell_nav.dart';
import '../../widgets/bulk_actions.dart';
import '../../widgets/confirm.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/track_actions.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import '../import/import_banner.dart';
import '../library/album_detail_screen.dart' show tracksAndMinutes;
import 'add_tracks_screen.dart';
import 'export_dialog.dart';
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
  bool _editing = false;

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
    final store = ref.read(coverStoreProvider);
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
    final cc = context.cc;
    final id = widget.playlist.id;
    final tracks =
        ref.watch(playlistTracksProvider(id)).value ?? const <Track>[];
    final repo = ref.read(playlistRepositoryProvider);
    final summary = ref
        .watch(playlistsProvider)
        .value
        ?.where((p) => p.playlist.id == id)
        .firstOrNull;
    final custom = summary?.playlist.coverKey;
    final compact = ref.watch(settingsProvider).compactMode;
    final ctrl = ref.read(playerControllerProvider);
    final playCtx = PlayContext(PlayContextKind.playlist, _name);
    final coverKeys = playlistCoverKeys(custom, tracks.map((t) => t.coverKey));
    final durationMs = tracks.fold<int>(0, (a, t) => a + t.durationMs);
    final extent = trackRowExtentOf(context, compact);
    final key = 'playlist:$id';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in tracks) t.id],
    );

    Future<void> remove(Track t, int i) async {
      await repo.removeTrack(id, t.id);
      if (!context.mounted) return;
      showUndoSnack(context, l.removedFromPlaylist, () async {
        await repo.addTracks(id, [t.id]);
        await repo.reorder(id, tracks.length - 1, i);
      });
    }

    void rowMenu(Track t, int i) => showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_remove_rounded),
              title: Text(l.removeFromPlaylistAction),
              onTap: () {
                Navigator.of(sheet).pop();
                remove(t, i);
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz_rounded),
              title: Text(l.moreActions),
              onTap: () {
                Navigator.of(sheet).pop();
                showTrackActions(context, ref, t);
              },
            ),
          ],
        ),
      ),
    );

    final Widget list;
    if (tracks.isEmpty) {
      list = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.queue_music_rounded, size: 56, color: cc.textFaint),
              const SizedBox(height: 12),
              Text(l.noTracksInPlaylist, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ShellNav.open<void>(
                  context,
                  AddTracksScreen(playlistId: id),
                ),
                child: Text(l.addSongs),
              ),
            ],
          ),
        ),
      );
    } else if (_editing) {
      list = SliverReorderableList(
        proxyDecorator: (child, _, anim) => ccDragProxy(context, child, anim),
        itemCount: tracks.length,
        onReorderItem: (from, to) => repo.reorder(id, from, to),
        itemBuilder: (_, i) {
          final t = tracks[i];
          return Material(
            key: ValueKey('pl-edit-${t.id}'),
            color: Colors.transparent,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: CcDims.margin),
                      child: Icon(Icons.drag_handle_rounded),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          t.artist ?? l.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.removeFromPlaylistAction,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => remove(t, i),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      list = SliverList.builder(
        itemCount: tracks.length,
        itemBuilder: (_, i) {
          final t = tracks[i];
          return SizedBox(
            height: extent,
            child: LiveTrackRow(
              track: t,
              compact: compact,
              selection: selection,
              onMore: () => rowMenu(t, i),
              onTap: () => ctrl.playFromList(tracks, i, context: playCtx),
            ),
          );
        },
      );
    }

    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: CollectionScaffold(
        selectionBar: SelectionBarSlot(
          listKey: key,
          tracks: tracks,
          bulk: BulkContext(playlistId: id),
        ),
        title: _name,
        name: _name,
        coverKey: coverKeys.firstOrNull,
        cover: (s) =>
            PlaylistCover(size: s, coverKeys: coverKeys, radius: CcDims.rGrid),
        meta:
            '${l.kindPlaylist} · ${tracksAndMinutes(context, tracks.length, durationMs)}',
        onPlay: tracks.isEmpty
            ? null
            : () => ctrl.playFromList(tracks, 0, context: playCtx),
        onShuffle: tracks.isEmpty
            ? null
            : () async {
                await ctrl.setShuffle(true);
                await ctrl.playFromList(tracks, 0, context: playCtx);
              },
        menu: PopupMenuButton<String>(
          tooltip: l.moreActions,
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) async {
            switch (v) {
              case 'edit':
                // Reordering and picking do not mix.
                ref.read(selectionProvider(key).notifier).clear();
                setState(() => _editing = !_editing);
              case 'add':
                ShellNav.open<void>(context, AddTracksScreen(playlistId: id));
              case 'cover':
                await _pickCover(id);
              case 'clear':
                await repo.setCover(id, null);
              case 'export':
                await exportPlaylistFlow(
                  context,
                  ref,
                  playlist: widget.playlist,
                  name: _name,
                  tracks: tracks,
                );
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
            PopupMenuItem(
              value: 'edit',
              child: Text(_editing ? l.finishEditing : l.editOrder),
            ),
            PopupMenuItem(value: 'add', child: Text(l.addSongs)),
            PopupMenuItem(value: 'cover', child: Text(l.playlistChangeCover)),
            if (custom != null)
              PopupMenuItem(value: 'clear', child: Text(l.playlistRemoveCover)),
            PopupMenuItem(value: 'export', child: Text(l.exportPlaylist)),
            PopupMenuItem(value: 'rename', child: Text(l.rename)),
            PopupMenuItem(value: 'delete', child: Text(l.delete)),
          ],
        ),
        slivers: [
          SliverToBoxAdapter(child: ImportBanner(playlistId: id)),
          list,
        ],
      ),
    );
  }
}
