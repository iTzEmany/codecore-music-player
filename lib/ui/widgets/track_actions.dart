import '../../services/audio/online_entries.dart';
import 'cc_sheet.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/constants.dart';
import '../../core/platform.dart';
import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/equalizer_providers.dart';
import '../../providers/jam_providers.dart';
import '../../providers/pending_playlist_adds.dart' show addToPlaylistTag;
import '../../providers/player_providers.dart';
import '../../providers/preview_providers.dart';
import '../../providers/suggestion_actions.dart';
import '../../providers/track_ops.dart';
import '../../providers/youtube_providers.dart' show downloadsProvider;
import '../screens/playlists/playlist_dialogs.dart';
import '../screens/playlists/playlist_picker.dart';
import '../screens/tags/tags_sheet.dart';
import '../screens/enrich_preview_dialog.dart';
import '../screens/settings/equalizer_screen.dart';
import '../screens/devices/devices_sheet.dart';
import '../screens/track_edit_dialog.dart';
import '../screens/library/album_detail_screen.dart';
import '../screens/library/artist_screen.dart';
import '../screens/online/artist_page_screen.dart';
import '../screens/online/artist_picker_sheet.dart';
import '../shell/shell_nav.dart';
import '../../services/online/youtube_service.dart' show YtResult;
import '../../services/stream/stream_key.dart' show keyOfStreamPath, streamResultOfRow;
import '../../services/online/ytm_artist.dart' show YtmArtistRef;
import '../../data/repositories/library_queries.dart';
import '../../data/repositories/track_kinds.dart';
import '../../providers/library_providers.dart';
import '../theme/tokens.dart';
import 'track_art.dart';
import 'radio_now.dart';
import '../screens/radio/radio_actions.dart';
import '../../providers/radio_providers.dart' show savedRadioIdsProvider;
import '../../services/radio/radio_station.dart';
import 'delete_tracks.dart';
import 'favorite_actions.dart';
import 'format_utils.dart';
import 'quality_tag.dart';
import 'show_msg.dart';

/// One entry of the track menu.
class TrackAction {
  const TrackAction(
    this.icon,
    this.label,
    this.run, {
    this.destructive = false,
    this.onStreamRow = false,
  });

  final bool destructive;

  /// Kept in the menu of a streamed shadow row (kind 2).
  final bool onStreamRow;
  final IconData icon;
  final String label;
  final Future<void> Function() run;
}

class TrackActionGroup {
  const TrackActionGroup(this.title, this.actions);

  final String title;
  final List<TrackAction> actions;
}

/// Streamed (online) entries are not library rows: no favourites, tags,
/// playlists by id, edit, lyrics, share, details of a file or deletion. They
/// can be downloaded, downloaded into a playlist, disliked or taken out of
/// the queue.
List<TrackActionGroup> onlineTrackActions(
  BuildContext outer,
  WidgetRef ref,
  Track track,
) {
  final l = outer.l10n;
  final actions = ref.read(suggestionActionsProvider);
  void snack(String text) => showMsg(outer, text);

  return [
    TrackActionGroup(l.groupCollection, [
      TrackAction(Icons.download_rounded, l.ytDownload, () async {
        if (actions.downloadEntry(track.id)) snack(l.suggestionDownloadStarted);
      }),
      TrackAction(Icons.playlist_add_rounded, l.addToPlaylist, () async {
        final picked = await pickPlaylist(outer, ref);
        if (picked == null) return;
        if (actions.addToPlaylist(track.id, picked.id)) {
          snack(l.suggestionAddWhenDownloaded(picked.name));
        }
      }),
    ]),
    TrackActionGroup(l.groupQueue, [
      TrackAction(Icons.thumb_down_outlined, l.suggestionDislike, () async {
        await actions.dislike(track.id);
        snack(l.suggestionDisliked);
      }),
      TrackAction(Icons.remove_circle_outline_rounded, l.removeFromQueueAction,
          () => actions.remove(track.id)),
    ]),
  ];
}

/// A radio in the queue is not a track: it can be saved in «Le mie radio» (or
/// taken out), the song on air looked up, and the station taken out of the
/// queue. No favourites, downloads, playlists or tags.
List<TrackActionGroup> radioTrackActions(
  BuildContext outer,
  WidgetRef ref,
  Track track,
  RadioStation station,
) {
  final l = outer.l10n;
  final saved = ref.read(savedRadioIdsProvider).contains(station.id);
  final onAir = ref.read(audioHandlerProvider).onAir;
  final isCurrent = ref.read(currentTrackProvider).value?.id == track.id;
  return [
    TrackActionGroup(l.groupCollection, [
      TrackAction(
        saved ? Icons.star_rounded : Icons.star_border_rounded,
        saved ? l.radioUnsave : l.radioSave,
        () => toggleSavedRadio(outer, ref, station),
      ),
      if (isCurrent && onAir != null && kEnableYoutube)
        TrackAction(Icons.search_rounded, l.radioSearchSong, () async => searchOnAir(outer, ref, onAir)),
    ]),
    TrackActionGroup(l.groupQueue, [
      TrackAction(Icons.remove_circle_outline_rounded, l.removeFromQueueAction,
          () => ref.read(suggestionActionsProvider).remove(track.id)),
    ]),
  ];
}

/// The single model of the track actions, used by the bottom sheet (mobile:
/// long press, ⋮) and by the pointer menu (desktop: right click).
/// [outer] is the context the effects (snackbars, pages) are tied to.
List<TrackActionGroup> trackActions(
  BuildContext outer,
  WidgetRef ref,
  Track track,
) {
  final radio = radioOfTrackRead(ref, track);
  if (radio != null) return radioTrackActions(outer, ref, track, radio);
  if (isOnlineId(track.id)) return onlineTrackActions(outer, ref, track);
  final l = outer.l10n;
  final ctrl = ref.read(playerControllerProvider);
  void snack(String text) => showMsg(outer, text);

  Future<void> goToAlbum() async {
    final albums = await ref.read(albumsProvider.future);
    final found = albums.where((a) => a.albumKey == track.albumKey).firstOrNull;
    if (found == null || !outer.mounted) return;
    ShellNav.openInLibrary(outer, ref, AlbumDetailScreen(album: found));
  }

  void goToArtist() {
    final key = (track.artist ?? '').trim().toLowerCase();
    ShellNav.openInLibrary(
      outer,
      ref,
      ArtistDetailScreen(
        artist: ArtistSummary(
          key: key,
          name: track.artist,
          trackCount: 0,
          albumCount: 0,
        ),
      ),
    );
  }

  Future<void> artistOnYoutubeMusic() => openYtmArtist(outer, ref, track.artist!.trim(),
      open: (page) => ShellNav.openInLibrary(outer, ref, page));

  final groups = [
    TrackActionGroup(l.groupQueue, [
      if (isDesktop)
        TrackAction(Icons.hearing_rounded, l.previewTrack, () async {
          await ref.read(previewProvider.notifier).start(track);
        }),
      if (track.resumePositionMs != null)
        TrackAction(Icons.restart_alt_rounded, l.restartFromBeginning, () async {
          // The bookmark goes first: the player reads it when it loads the track.
          await ref.read(trackOpsProvider).setResumePosition(track.id, null);
          await ctrl.playFromList([track], 0);
        }),
      TrackAction(Icons.playlist_play_rounded, l.playNext, () async {
        ctrl.playNext(track.id);
        snack(l.playNextDone);
      }, onStreamRow: true),
      TrackAction(Icons.queue_rounded, l.addToQueue, () async {
        ctrl.addToQueue(track.id);
        snack(l.addedToQueue);
      }, onStreamRow: true),
      if (ref.read(jamProvider).active)
        TrackAction(Icons.queue_music_rounded, l.jamAddToJam, () async {
          final n = await ref.read(jamProvider.notifier).addTracks([track]);
          snack(l.jamAdded(n));
        }),
    ]),
    TrackActionGroup(l.groupCollection, [
      // A streamed shadow row: the download promotes it to a real library track.
      if (track.kind == kStreamKind && keyOfStreamPath(track.path) != null)
        TrackAction(Icons.download_rounded, l.ytDownload, () async {
          ref
              .read(downloadsProvider.notifier)
              .add(streamResultOfRow(keyOfStreamPath(track.path)!, track));
        }, onStreamRow: true),
      TrackAction(
        track.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        track.isFavorite ? l.removeFromFavorites : l.favorite,
        () => toggleFavorite(outer, ref, track),
      ),
      TrackAction(
        Icons.playlist_add_rounded,
        l.addToPlaylist,
        () async => showAddToPlaylistSheet(outer, ref, [track]),
      ),
      TrackAction(
        Icons.label_outline_rounded,
        l.tagsEllipsis,
        () async => showTagsSheet(outer, ref, [track]),
      ),
    ]),
    TrackActionGroup(l.groupGoTo, [
      TrackAction(Icons.album_outlined, l.goToAlbum, goToAlbum),
      if ((track.artist ?? '').trim().isNotEmpty)
        TrackAction(
          Icons.person_outline_rounded,
          l.goToArtist,
          () async => goToArtist(),
        ),
      if (kEnableYoutube && (track.artist ?? '').trim().isNotEmpty)
        TrackAction(
          Icons.smart_display_rounded,
          l.ytmArtistOnYoutubeMusic,
          artistOnYoutubeMusic,
        ),
    ]),
    TrackActionGroup(l.groupEdit, [
      TrackAction(
        Icons.edit_outlined,
        l.editInfo,
        () async => showTrackEditDialog(outer, track),
      ),
      TrackAction(
        Icons.travel_explore_rounded,
        l.searchWeb,
        () async => showEnrichPreview(outer, track),
      ),
    ]),
    TrackActionGroup(l.groupOther, [
      // From Now Playing's ⋯ (the playing track's menu), where the equalizer is.
      if (ref.read(equalizerProvider) != null &&
          ref.read(currentTrackProvider).value?.id == track.id)
        TrackAction(Icons.equalizer_rounded, l.equalizer, () async {
          ShellNav.open<void>(outer, const EqualizerScreen());
        }),
      TrackAction(
        Icons.devices_rounded,
        l.shareMenu,
        () async => DevicesSheet.show(outer, trackIds: [track.id]),
      ),
      TrackAction(Icons.info_outline_rounded, l.details, () async {
        showDialog<void>(
          context: outer,
          builder: (_) => _DetailsDialog(track: track),
        );
      }, onStreamRow: true),
      if (isDesktop)
        TrackAction(
          Icons.folder_open_rounded,
          l.showInFolder,
          () async => revealInFolder(track.path),
        ),
      // The file itself, not just a list: music only (episodes have their own
      // cleanup).
      if (track.kind == 0)
        TrackAction(
          Icons.delete_forever_rounded,
          l.deleteFromDevice,
          () async {
            await confirmAndDeleteTracks(outer, ref, [track]);
          },
          destructive: true,
        ),
    ]),
  ];
  // A streamed shadow row (kind 2) keeps only queue actions and Details until phase 46.
  if (track.kind != kStreamKind) return groups;
  return [
    for (final g in groups)
      if (g.actions.any((a) => a.onStreamRow))
        TrackActionGroup(g.title, g.actions.where((a) => a.onStreamRow).toList()),
  ];
}

Future<void> showTrackActions(
  BuildContext context,
  WidgetRef ref,
  Track track,
) {
  final groups = trackActions(context, ref, track);
  return showCcSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => _TrackActionsSheet(track: track, groups: groups),
  );
}

/// Right click on desktop: the same actions as a menu at the pointer.
Future<void> showTrackContextMenu(
  BuildContext context,
  WidgetRef ref,
  Track track,
  Offset position,
) async {
  final groups = trackActions(context, ref, track);
  // `showMenu` positions inside the nearest overlay, which is offset from
  // the window (sidebar, nested navigators): convert the pointer position.
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(position);
  final entries = <PopupMenuEntry<TrackAction>>[];
  for (var g = 0; g < groups.length; g++) {
    if (g > 0) entries.add(const PopupMenuDivider());
    for (final a in groups[g].actions) {
      entries.add(
        PopupMenuItem<TrackAction>(
          value: a,
          child: Row(
            children: [
              Icon(a.icon, size: 20),
              const SizedBox(width: 12),
              Flexible(child: Text(a.label)),
            ],
          ),
        ),
      );
    }
  }
  final picked = await showMenu<TrackAction>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(local.dx, local.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    items: entries,
  );
  if (picked != null) await picked.run();
}

class _TrackActionsSheet extends StatelessWidget {
  const _TrackActionsSheet({required this.track, required this.groups});

  final Track track;
  final List<TrackActionGroup> groups;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(CcDims.gap16, CcDims.gap4, CcDims.gap16, CcDims.gap12),
              child: Row(
                children: [
                  TrackArt(track: track, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall,
                        ),
                        Text(
                          track.artist ?? l.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium,
                        ),
                        if (track.album != null && track.album!.isNotEmpty)
                          Text(
                            track.album!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall?.copyWith(color: cc.textFaint),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final (i, g) in groups.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              for (final a in g.actions)
                ListTile(
                  leading: Icon(a.icon),
                  iconColor: a.destructive ? cc.error : null,
                  textColor: a.destructive ? cc.error : null,
                  title: Text(a.label),
                  onTap: () {
                    Navigator.of(context).pop();
                    a.run();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens the containing folder without a shell; arguments are passed as a list.
Future<void> revealInFolder(String path) async {
  try {
    if (Platform.isWindows) {
      final windir = Platform.environment['WINDIR'] ?? r'C:\Windows';
      await Process.start('$windir\\explorer.exe', ['/select,$path']);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [p.dirname(path)]);
    }
  } on Object catch (e, st) {
    AppLog.w('reveal in folder failed: $path', e, st);
  }
}

class _DetailsDialog extends StatelessWidget {
  const _DetailsDialog({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String mb(int bytes) => '${(bytes / 1048576).toStringAsFixed(1)} MB';
    final added = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(DateTime.fromMillisecondsSinceEpoch(track.addedAt));
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k)),
          Expanded(child: SelectableText(v)),
        ],
      ),
    );
    return AlertDialog(
      title: Text(track.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(l.detailPath, track.path),
            row(l.detailFormat, track.format.toUpperCase()),
            Align(alignment: Alignment.centerLeft, child: QualityTag(track)),
            row(l.detailSize, mb(track.sizeBytes)),
            row(l.detailDuration, formatDuration(track.durationMs)),
            row(l.detailAdded, added),
            row(l.detailPlays, '${track.playCount}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}

/// The menu of an online row: play after, queue, playlist, download, artist
/// (R-16). With a Jam on, «Riproduci dopo» goes to the shared queue (D-89).
List<TrackAction> onlineResultActions(
  BuildContext outer,
  WidgetRef ref,
  YtResult r,
) {
  final l = outer.l10n;
  final ctrl = ref.read(playerControllerProvider);
  final jam = ref.read(jamProvider).active;
  return [
    TrackAction(Icons.playlist_play_rounded, l.playNext, () async {
      await (jam ? ctrl.enqueueOnline(r) : ctrl.playOnlineNext(r));
      if (outer.mounted) showMsg(outer, jam ? l.addedToQueue : l.playNextDone);
    }),
    TrackAction(Icons.queue_rounded, l.addToQueue, () async {
      await ctrl.enqueueOnline(r);
      if (outer.mounted) showMsg(outer, l.addedToQueue);
    }),
    TrackAction(Icons.playlist_add_rounded, l.addToPlaylist, () async {
      final picked = await pickPlaylist(outer, ref);
      if (picked == null || !outer.mounted) return;
      ref
          .read(downloadsProvider.notifier)
          .add(r, tag: addToPlaylistTag(picked.id));
      if (outer.mounted) {
        showMsg(outer, l.suggestionAddWhenDownloaded(picked.name));
      }
    }),
    TrackAction(Icons.download_rounded, l.ytDownload, () async {
      ref.read(downloadsProvider.notifier).add(r);
      if (outer.mounted) showMsg(outer, l.suggestionDownloadStarted);
    }),
    TrackAction(Icons.person_outline_rounded, l.goToArtist, () async {
      final who = r.artistIds.indexWhere((id) => id.isNotEmpty);
      if (who >= 0 && who < r.artists.length) {
        ShellNav.open<void>(
          outer,
          ArtistPageScreen(
            artist: YtmArtistRef(id: r.artistIds[who], name: r.artists[who]),
          ),
        );
      } else if (r.artists.isNotEmpty) {
        await openYtmArtist(
          outer,
          ref,
          r.artists.first,
          open: (page) => ShellNav.open<void>(outer, page),
        );
      } else {
        showMsg(outer, l.ytmArtistNone);
      }
    }),
  ];
}

Future<void> showOnlineActions(
  BuildContext context,
  WidgetRef ref,
  YtResult r,
) {
  final actions = onlineResultActions(context, ref, r);
  return showCcSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                r.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                r.artists.isEmpty ? r.channel : r.artists.join(', '),
              ),
            ),
            for (final a in actions)
              ListTile(
                leading: Icon(a.icon),
                title: Text(a.label),
                onTap: () {
                  Navigator.of(sheet).pop();
                  a.run();
                },
              ),
          ],
        ),
      ),
    ),
  );
}
