import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/database_providers.dart';
import '../../providers/jam_providers.dart';
import '../../providers/player_providers.dart';
import '../screens/cleanup/move_to_album_dialog.dart';
import '../screens/playlists/playlist_dialogs.dart';
import '../screens/tags/tags_sheet.dart';
import 'confirm.dart';
import 'track_actions.dart';

/// Where a selection lives: decides which actions make sense.
class BulkContext {
  const BulkContext({this.playlistId});

  /// Inside a playlist: «Rimuovi dalla playlist» is offered.
  final int? playlistId;
}

/// The actions for many tracks at once, in the same model as the single-track
/// menu. [tracks] must be in the order of the list, not of the clicks; [done]
/// leaves the selection after an action that went through.
///
/// None of them touches a file: «remove» only ever means rows of the library
/// or of a playlist.
List<TrackActionGroup> bulkActions(
  BuildContext outer,
  WidgetRef ref,
  List<Track> tracks,
  BulkContext ctx, {
  required VoidCallback done,
}) {
  final l = outer.l10n;
  final ctrl = ref.read(playerControllerProvider);
  final n = tracks.length;

  void snack(String text) {
    if (!outer.mounted) return;
    ScaffoldMessenger.of(outer)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  final allFavorite = tracks.isNotEmpty && tracks.every((t) => t.isFavorite);
  final allMissing = tracks.isNotEmpty && tracks.every((t) => t.missing);

  Future<void> favorites() async {
    final target = !allFavorite;
    final changed = [
      for (final t in tracks)
        if (t.isFavorite != target) t.id,
    ];
    final repo = ref.read(trackRepositoryProvider);
    await repo.setFavoriteMany(changed, target);
    if (!outer.mounted) return;
    showUndoSnack(
      outer,
      target
          ? l.favoritesAdded(changed.length)
          : l.favoritesRemoved(changed.length),
      () => repo.setFavoriteMany(changed, !target),
    );
    done();
  }

  Future<void> removeFromPlaylist(int playlistId) async {
    final ok = await showConfirm(
      outer,
      title: l.removeManyFromPlaylistTitle(n),
      body: l.removeManyFromPlaylistBody,
      confirmLabel: l.removeFromList,
    );
    if (!ok) return;
    final repo = ref.read(playlistRepositoryProvider);
    final ids = [for (final t in tracks) t.id];
    final before = await repo.removeTracks(playlistId, ids);
    if (!outer.mounted) return;
    showUndoSnack(
      outer,
      l.removedManyFromPlaylist(n),
      () => repo.restoreTracks(playlistId, before, ids),
    );
    done();
  }

  Future<void> removeFromLibrary() async {
    final ok = await showConfirm(
      outer,
      title: l.removeManyFromLibraryTitle(n),
      body: l.removeManyFromLibraryBody,
      confirmLabel: l.removeFromList,
      destructive: true,
    );
    if (!ok) return;
    final removed = await ref.read(trackRepositoryProvider).deleteMissingTracks(
      [for (final t in tracks) t.id],
    );
    snack(l.removedManyFromLibrary(removed));
    done();
  }

  return [
    TrackActionGroup(l.groupQueue, [
      TrackAction(Icons.play_arrow_rounded, l.play, () async {
        await ctrl.playFromList(tracks, 0);
        done();
      }),
      TrackAction(Icons.playlist_play_rounded, l.playNext, () async {
        // Each one goes right after the playing track: reversed, so the list
        // order is the play order.
        for (final t in tracks.reversed) {
          ctrl.playNext(t.id);
        }
        snack(l.playNextMany(n));
        done();
      }),
      TrackAction(Icons.queue_rounded, l.addToQueue, () async {
        for (final t in tracks) {
          ctrl.addToQueue(t.id);
        }
        snack(l.addedToQueueMany(n));
        done();
      }),
      if (ref.read(jamProvider).active)
        TrackAction(Icons.queue_music_rounded, l.jamAddToJam, () async {
          final added = await ref.read(jamProvider.notifier).addTracks(tracks);
          snack(l.jamAdded(added));
          done();
        }),
    ]),
    TrackActionGroup(l.groupCollection, [
      TrackAction(
        allFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        allFavorite ? l.bulkRemoveFromFavorites : l.bulkAddToFavorites,
        favorites,
      ),
      TrackAction(Icons.playlist_add_rounded, l.addToPlaylist, () async {
        if (await showAddToPlaylistSheet(outer, ref, tracks)) done();
      }),
      TrackAction(Icons.label_outline_rounded, l.tagAddToSelection, () async {
        await pickTagFor(outer, ref, tracks, remove: false, done: done);
      }),
      TrackAction(Icons.label_off_outlined, l.tagRemoveFromSelection, () async {
        await pickTagFor(outer, ref, tracks, remove: true, done: done);
      }),
      TrackAction(Icons.album_outlined, l.moveToAlbum, () async {
        if (await showMoveToAlbumDialog(outer, ref, tracks)) done();
      }),
      if (ctx.playlistId != null)
        TrackAction(
          Icons.playlist_remove_rounded,
          l.removeFromPlaylistAction,
          () => removeFromPlaylist(ctx.playlistId!),
        ),
    ]),
    // Only for tracks whose file is gone: the library row has nothing left to
    // point to. Music that still exists is never removable from here.
    if (allMissing)
      TrackActionGroup(l.groupOther, [
        TrackAction(
          Icons.delete_outline_rounded,
          l.removeFromLibrary,
          removeFromLibrary,
        ),
      ]),
  ];
}
