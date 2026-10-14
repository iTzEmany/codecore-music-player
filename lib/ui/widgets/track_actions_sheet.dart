import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/app_log.dart';
import '../../core/platform.dart';
import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/player_providers.dart';
import '../screens/playlists/playlist_dialogs.dart';
import '../screens/enrich_preview_dialog.dart';
import '../screens/track_edit_dialog.dart';
import 'favorite_actions.dart';
import 'format_utils.dart';
import 'quality_badge.dart';

Future<void> showTrackActions(
    BuildContext context, WidgetRef ref, Track track) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => _TrackActionsSheet(track: track, outer: context),
  );
}

class _TrackActionsSheet extends ConsumerWidget {
  const _TrackActionsSheet({required this.track, required this.outer});

  final Track track;
  final BuildContext outer;

  void _snack(String text) {
    if (!outer.mounted) return;
    ScaffoldMessenger.of(outer)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ctrl = ref.read(playerControllerProvider);
    void close() => Navigator.of(context).pop();
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(track.artist ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(l.playNext),
            onTap: () {
              ctrl.playNext(track.id);
              close();
              _snack(l.addedToQueue);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue),
            title: Text(l.addToQueue),
            onTap: () {
              ctrl.addToQueue(track.id);
              close();
              _snack(l.addedToQueue);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(l.addToPlaylist),
            onTap: () {
              close();
              showAddToPlaylistSheet(outer, ref, [track]);
            },
          ),
          ListTile(
            leading: Icon(track.isFavorite
                ? Icons.favorite
                : Icons.favorite_border),
            title: Text(track.isFavorite ? l.removeFromFavorites : l.favorite),
            onTap: () {
              close();
              toggleFavorite(outer, ref, track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l.editInfo),
            onTap: () {
              close();
              showTrackEditDialog(outer, track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.travel_explore),
            title: Text(l.searchWeb),
            onTap: () {
              close();
              showEnrichPreview(outer, track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.details),
            onTap: () {
              close();
              showDialog<void>(
                  context: outer, builder: (_) => _DetailsDialog(track: track));
            },
          ),
          if (isDesktop)
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(l.showInFolder),
              onTap: () {
                close();
                revealInFolder(track.path);
              },
            ),
        ]),
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
    final added = DateTime.fromMillisecondsSinceEpoch(track.addedAt);
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 110, child: Text(k)),
            Expanded(child: SelectableText(v)),
          ]),
        );
    return AlertDialog(
      title: Text(track.title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          row(l.detailPath, track.path),
          row(l.detailFormat, track.format.toUpperCase()),
          Align(alignment: Alignment.centerLeft, child: QualityBadge(track)),
          row(l.detailSize, mb(track.sizeBytes)),
          row(l.detailDuration, formatDuration(track.durationMs)),
          row(l.detailAdded, added.toIso8601String().substring(0, 10)),
          row(l.detailPlays, '${track.playCount}'),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close)),
      ],
    );
  }
}
