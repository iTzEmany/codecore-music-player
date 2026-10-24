import '../../widgets/cc_sheet.dart';
import 'package:flutter/material.dart';
import '../../widgets/create_flows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../widgets/playlist_cover.dart';

/// A playlist chosen from the sheet (or created there).
typedef PickedPlaylist = ({int id, String name});

/// Asks which playlist to use, without adding anything yet. Null when the
/// sheet is dismissed.
Future<PickedPlaylist?> pickPlaylist(BuildContext context, WidgetRef ref) =>
    showCcSheet<PickedPlaylist>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Consumer(
          builder: (_, ref, _) {
            final l = sheet.l10n;
            final lists = ref.watch(playlistsProvider).value ?? const [];
            return ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l.newPlaylistEllipsis),
                  onTap: () async {
                    final r = await createPlaylistFlow(sheet, ref);
                    if (r != null && sheet.mounted) Navigator.of(sheet).pop(r);
                  },
                ),
                for (final p in lists)
                  ListTile(
                    leading: PlaylistCover(
                      size: 40,
                      coverKeys: playlistCoverKeys(p.playlist.coverKey, [p.autoCoverKey]),
                    ),
                    title: Text(p.playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(l.playlistCountLabel(p.trackCount)),
                    onTap: () => Navigator.of(sheet).pop((id: p.playlist.id, name: p.playlist.name)),
                  ),
              ],
            );
          },
        ),
      ),
    );
