import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/smart_playlist_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/collection_header.dart';
import '../../widgets/confirm.dart';
import '../../widgets/smart_cover.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import 'smart_playlist_editor.dart';

/// A smart playlist: its tracks come from the rules and change by themselves,
/// so the page is read-only (no reordering, no «add songs»).
class SmartPlaylistScreen extends ConsumerWidget {
  const SmartPlaylistScreen({super.key, required this.id});

  final int id;

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    SmartPlaylist p,
    List<Track> tracks,
  ) async {
    final repo = ref.read(playlistRepositoryProvider);
    final copy = await repo.create(p.name);
    await repo.addTracks(copy, [for (final t in tracks) t.id]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.smartConverted(p.name))),
      );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, SmartPlaylist p) async {
    final l = context.l10n;
    final ok = await showConfirm(
      context,
      title: l.smartDeleteTitle(p.name),
      body: l.smartDeleteBody,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(smartPlaylistRepositoryProvider).delete(p.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final p = ref.watch(smartPlaylistProvider(id)).value;
    final tracks = ref.watch(smartTracksProvider(id)).value ?? const <Track>[];
    if (p == null) return const Scaffold();
    final compact = ref.watch(settingsProvider).compactMode;
    final ctrl = ref.read(playerControllerProvider);
    final playCtx = PlayContext(PlayContextKind.playlist, p.name);
    final extent = trackRowExtentOf(context, compact);
    final key = 'smart:$id';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in tracks) t.id],
    );
    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: CollectionScaffold(
        selectionBar: SelectionBarSlot(listKey: key, tracks: tracks),
        title: p.name,
        name: p.name,
        cover: (s) => SmartCover(size: s, radius: CcDims.rGrid),
        subtitle: Text(
          p.rules.isEmpty ? l.smartNoRules : p.rules,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cc.textMuted),
        ),
        meta: l.smartSubtitle(tracks.length),
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
                await ShellNav.open<bool>(context, SmartPlaylistEditor(existing: p));
              case 'convert':
                await _convert(context, ref, p, tracks);
              case 'delete':
                await _delete(context, ref, p);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(l.smartPlaylistEdit)),
            PopupMenuItem(value: 'convert', child: Text(l.smartConvert)),
            PopupMenuItem(value: 'delete', child: Text(l.delete)),
          ],
        ),
        slivers: [
          SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (_, i) => SizedBox(
              height: extent,
              child: LiveTrackRow(
                track: tracks[i],
                compact: compact,
                selection: selection,
                onTap: () => ctrl.playFromList(tracks, i, context: playCtx),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
