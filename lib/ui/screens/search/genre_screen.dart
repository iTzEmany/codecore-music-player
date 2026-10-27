import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/collection_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import '../library/album_detail_screen.dart' show collectionMeta;
import '../../widgets/cc_app_bar.dart';

/// Tracks of one genre.
class GenreScreen extends ConsumerWidget {
  const GenreScreen({super.key, required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tracks =
        ref.watch(genreTracksProvider(genre)).value ?? const <Track>[];
    final ctrl = ref.read(playerControllerProvider);
    final compact = ref.watch(settingsProvider).compactMode;
    final ctx = PlayContext(PlayContextKind.playlist, genre);
    final key = SelectionKey.genreOf(genre);
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in tracks) t.id],
    );
    if (tracks.isEmpty) {
      return Scaffold(
        appBar: CcAppBar(title: genre),
        body: EmptyState(
          icon: Icons.music_note_rounded,
          message: l.noResults,
        ),
      );
    }
    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: CollectionScaffold(
        selectionBar: SelectionBarSlot(listKey: key, tracks: tracks),
        title: genre,
        name: genre,
        meta: collectionMeta(
          l,
          tracks: tracks.length,
          durationMs: tracks.fold<int>(0, (sum, t) => sum + t.durationMs),
        ),
        onPlay: () => ctrl.playAll(tracks, context: ctx),
        shuffleIds: tracks.isEmpty ? null : [for (final t in tracks) t.id],
        slivers: [
          SliverFixedExtentList.builder(
            itemExtent: trackRowExtentOf(context, compact),
            itemCount: tracks.length,
            itemBuilder: (_, i) => LiveTrackRow(
              track: tracks[i],
              compact: compact,
              selection: selection,
              onTap: () => ctrl.playFromList(tracks, i, context: ctx),
            ),
          ),
        ],
      ),
    );
  }
}
