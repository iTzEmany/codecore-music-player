import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/track_repository.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/ui_providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/track_tile.dart';
import 'folders_sheet.dart';

String _sortLabel(BuildContext context, SortOption o) {
  final l = context.l10n;
  return switch (o) {
    SortOption.defaultOrder => l.sortDefault,
    SortOption.title => l.sortTitle,
    SortOption.artist => l.sortArtist,
    SortOption.album => l.sortAlbum,
    SortOption.year => l.sortYear,
    SortOption.addedAt => l.sortAdded,
    SortOption.duration => l.sortDuration,
  };
}

class TracksTab extends ConsumerStatefulWidget {
  const TracksTab({super.key});

  @override
  ConsumerState<TracksTab> createState() => _TracksTabState();
}

class _TracksTabState extends ConsumerState<TracksTab> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref
          .read(trackQueryProvider.notifier)
          .update((q) => q.copyWith(text: text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(tracksProvider);
    final query = ref.watch(trackQueryProvider);
    final folders = ref.watch(foldersProvider).value;
    final scan = ref.watch(scanStateProvider);
    final compact = ref.watch(settingsProvider).compactMode;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: ref.watch(searchFocusProvider),
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          PopupMenuButton<SortOption>(
            tooltip: context.l10n.sortBy,
            icon: const Icon(Icons.sort),
            initialValue: query.sort,
            onSelected: (s) => ref
                .read(trackQueryProvider.notifier)
                .update((q) => q.copyWith(sort: s)),
            itemBuilder: (_) => [
              for (final o in SortOption.values)
                PopupMenuItem(value: o, child: Text(_sortLabel(context, o))),
            ],
          ),
          IconButton(
            tooltip: context.l10n.folders,
            icon: const Icon(Icons.folder_open),
            onPressed: () => showModalBottomSheet<void>(
                context: context, builder: (_) => const FoldersSheet()),
          ),
        ]),
      ),
      if (scan.running)
        LinearProgressIndicator(
          value: (scan.progress == null || scan.progress!.total == 0)
              ? null
              : scan.progress!.done / scan.progress!.total,
        ),
      Expanded(
        child: tracks.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            if (list.isEmpty) {
              if (folders != null && folders.isEmpty) {
                return EmptyState(
                  icon: Icons.library_music,
                  message: context.l10n.addMusicFolder,
                  actionLabel: context.l10n.addFolder,
                  onAction: () => addFolderAndScan(ref),
                );
              }
              return EmptyState(
                  icon: query.text.isEmpty ? Icons.music_off : Icons.search_off,
                  message: query.text.isEmpty
                      ? (scan.running ? context.l10n.scanning : context.l10n.noTracks)
                      : context.l10n.noResults);
            }
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(context.l10n.tracksCount(list.length),
                        style: Theme.of(context).textTheme.bodySmall)),
              ),
              Expanded(
                child: ListView.builder(
                  itemExtent: trackRowExtent(compact),
                  itemCount: list.length,
                  itemBuilder: (_, i) => LiveTrackTile(
                    track: list[i],
                    compact: compact,
                    onTap: () => ref
                        .read(playerControllerProvider)
                        .playFromList(list, i),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    ]);
  }
}
