import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/track_repository.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/ui_providers.dart';
import '../../strings_it.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/track_tile.dart';
import 'folders_sheet.dart';

const _sortLabels = {
  SortOption.defaultOrder: S.sortDefault,
  SortOption.title: S.sortTitle,
  SortOption.artist: S.sortArtist,
  SortOption.album: S.sortAlbum,
  SortOption.year: S.sortYear,
  SortOption.addedAt: S.sortAdded,
  SortOption.duration: S.sortDuration,
};

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
              decoration: const InputDecoration(
                hintText: S.search,
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          PopupMenuButton<SortOption>(
            tooltip: S.sortBy,
            icon: const Icon(Icons.sort),
            initialValue: query.sort,
            onSelected: (s) => ref
                .read(trackQueryProvider.notifier)
                .update((q) => q.copyWith(sort: s)),
            itemBuilder: (_) => [
              for (final e in _sortLabels.entries)
                PopupMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
          IconButton(
            tooltip: S.folders,
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
                  message: S.addMusicFolder,
                  actionLabel: S.addFolder,
                  onAction: () => addFolderAndScan(ref),
                );
              }
              return EmptyState(
                  icon: query.text.isEmpty ? Icons.music_off : Icons.search_off,
                  message: query.text.isEmpty
                      ? (scan.running ? S.scanning : S.noTracks)
                      : S.noResults);
            }
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(S.tracksCount(list.length),
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
