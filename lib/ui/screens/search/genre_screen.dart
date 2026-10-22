import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/play_buttons.dart';
import '../../widgets/shuffle_button.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';

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
    final key = 'genre:$genre';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in tracks) t.id],
    );
    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: Scaffold(
        appBar: SelectableAppBar(
          listKey: key,
          tracks: tracks,
          normal: AppBar(title: Text(genre)),
        ),
        body: tracks.isEmpty
            ? Center(child: Text(l.noResults))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CcDims.margin,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PlayPill(
                            onPressed: () => ctrl.playAll(tracks, context: ctx),
                          ),
                          ShufflePill(onPressed: ctrl.toggleShuffle),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemExtent: trackRowExtentOf(context, compact),
                      itemCount: tracks.length,
                      itemBuilder: (_, i) => LiveTrackRow(
                        track: tracks[i],
                        compact: compact,
                        selection: selection,
                        onTap: () => ctrl.playFromList(tracks, i, context: ctx),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
