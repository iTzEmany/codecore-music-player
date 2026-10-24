import '../../widgets/cc_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/playlist_cover.dart';
import '../../widgets/prompt_name.dart';

/// What to say after adding [total] tracks of which [added] were new. One
/// track keeps the short message; several say how many were already there.
String addedToPlaylistText(
  AppLocalizations l, {
  required int total,
  required int added,
  required String name,
}) {
  final skipped = total - added;
  if (total == 1) return l.addedToPlaylist(name);
  if (added == 0) return l.allAlreadyInPlaylist(name);
  if (skipped == 0) return l.addedToPlaylistMany(added, name);
  return l.addedToPlaylistSkipped(added, skipped, name);
}

/// Argument: the track ids joined by «,» (a List has no value equality).
final _playlistsWithProvider = FutureProvider.autoDispose
    .family<Set<int>, String>(
      (ref, ids) => ref.watch(playlistRepositoryProvider).containing([
        for (final s in ids.split(',')) int.parse(s),
      ]),
    );

/// Bottom sheet to add tracks to an existing or a new playlist. Resolves to
/// true when they were added, false when the sheet was dismissed.
Future<bool> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks,
) async {
  final added = await showCcSheet<bool>(
    context: context,
    builder: (sheetContext) =>
        _AddToPlaylistSheet(tracks: tracks, outer: context),
  );
  return added ?? false;
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.tracks, required this.outer});

  final List<Track> tracks;
  final BuildContext outer;

  Future<void> _add(
    WidgetRef ref,
    BuildContext sheetContext,
    int id,
    String name,
  ) async {
    final repo = ref.read(playlistRepositoryProvider);
    final added = await repo.addTracks(id, [for (final t in tracks) t.id]);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop(true);
    if (outer.mounted) {
      ScaffoldMessenger.of(outer)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              addedToPlaylistText(
                outer.l10n,
                total: tracks.length,
                added: added,
                name: name,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lists = ref.watch(playlistsProvider).value ?? const [];
    // Playlists that already hold every picked track get a ✓.
    final contains =
        ref
            .watch(_playlistsWithProvider(tracks.map((t) => t.id).join(',')))
            .value ??
        const <int>{};
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l.newPlaylistEllipsis),
            onTap: () async {
              final name = await promptName(
                context,
                title: l.newPlaylist,
                confirmLabel: l.create,
                hint: l.playlistName,
              );
              if (name == null || !context.mounted) return;
              final id = await ref
                  .read(playlistRepositoryProvider)
                  .create(name);
              if (!context.mounted) return;
              await _add(ref, context, id, name);
            },
          ),
          for (final p in lists)
            ListTile(
              leading: PlaylistCover(
                size: 40,
                coverKeys: playlistCoverKeys(p.playlist.coverKey, [
                  p.autoCoverKey,
                ]),
              ),
              title: Text(
                p.playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(l.playlistCountLabel(p.trackCount)),
              trailing: contains.contains(p.playlist.id)
                  ? Icon(Icons.check_circle_rounded, color: context.cc.accent)
                  : null,
              onTap: () => _add(ref, context, p.playlist.id, p.playlist.name),
            ),
        ],
      ),
    );
  }
}
