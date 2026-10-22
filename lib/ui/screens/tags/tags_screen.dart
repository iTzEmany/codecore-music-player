import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/tag_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/play_buttons.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import 'tags_sheet.dart';

/// The user's tags with how many tracks each one has; a tap opens its tracks.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tags = ref.watch(tagsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tagsTitle),
        actions: [
          IconButton(
            tooltip: l.tagNew,
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final name = await askTagName(context);
              if (name != null) await ref.read(tagRepositoryProvider).create(name);
            },
          ),
        ],
      ),
      body: tags.isEmpty
          ? EmptyState(icon: Icons.label_outline_rounded, message: l.tagsEmpty)
          : ListView(
              children: [
                for (final s in tags)
                  ListTile(
                    leading: TagDot(s.tag, size: 16),
                    title: Text(s.tag.name),
                    subtitle: Text(l.tracksCount(s.trackCount)),
                    trailing: IconButton(
                      tooltip: l.moreOptions,
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => editTag(context, ref, s),
                    ),
                    onTap: () => ShellNav.open<void>(
                      context,
                      TagTracksScreen(name: s.tag.name),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The tracks that carry one tag (the rule `tag:<name>`).
class TagTracksScreen extends ConsumerWidget {
  const TagTracksScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tagTracksProvider(name)).value ?? const <Track>[];
    final compact = ref.watch(settingsProvider).compactMode;
    final ctrl = ref.read(playerControllerProvider);
    final key = 'tag:$name';
    final selection = RowSelection(
      listKey: key,
      visibleIds: [for (final t in tracks) t.id],
    );
    final ctx = PlayContext(PlayContextKind.playlist, name);
    return SelectionScope(
      listKey: key,
      visibleIds: selection.visibleIds,
      child: Scaffold(
        appBar: SelectableAppBar(
          listKey: key,
          tracks: tracks,
          normal: AppBar(
            title: Text(name),
            actions: [
              PlayCircleButton(
                size: 40,
                onPressed: tracks.isEmpty
                    ? null
                    : () => ctrl.playAll(tracks, context: ctx),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        body: ListView.builder(
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
    );
  }
}
