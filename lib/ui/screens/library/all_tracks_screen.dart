import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/track_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/play_buttons.dart';
import '../../widgets/track_row.dart';
import 'scan_status.dart';

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

/// Every track: count, search pill, sort chips, Shuffle and Play.
class AllTracksScreen extends ConsumerStatefulWidget {
  const AllTracksScreen({super.key});

  @override
  ConsumerState<AllTracksScreen> createState() => _AllTracksScreenState();
}

class _AllTracksScreenState extends ConsumerState<AllTracksScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  late final TrackQueryNotifier _query;

  @override
  void initState() {
    super.initState();
    // Captured now: `ref` must not be used from dispose().
    _query = ref.read(trackQueryProvider(false).notifier);
    // Starts clean: the Search tab shares this query.
    Future<void>.microtask(() => _query.update((q) => q.copyWith(text: '')));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => _query.update((q) => q.copyWith(text: text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tracks = ref.watch(tracksProvider(false));
    final query = ref.watch(trackQueryProvider(false));
    final compact = ref.watch(settingsProvider).compactMode;
    final ctrl = ref.read(playerControllerProvider);
    final theme = Theme.of(context).textTheme;
    final cc = context.cc;
    final ctx = PlayContext(
      query.text.trim().isEmpty
          ? PlayContextKind.library
          : PlayContextKind.search,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.allTracks)),
      body: Column(
        children: [
          const ScanStatus(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CcDims.margin,
              4,
              CcDims.margin,
              8,
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
              children: [
                for (final o in const [
                  SortOption.defaultOrder,
                  SortOption.title,
                  SortOption.artist,
                  SortOption.addedAt,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_sortLabel(context, o)),
                      selected: query.sort == o,
                      onSelected: (_) =>
                          _query.update((q) => q.copyWith(sort: o)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: tracks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => loadErrorState(
                context,
                e,
                st,
                onRetry: () => ref.invalidate(tracksProvider(false)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: query.text.isEmpty
                        ? Icons.music_off
                        : Icons.search_off,
                    message: query.text.isEmpty ? l.noTracks : l.noResults,
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CcDims.margin,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.tracksCount(list.length),
                              style: theme.bodyMedium?.copyWith(
                                color: cc.textMuted,
                              ),
                            ),
                          ),
                          ShuffleButton(
                            onPressed: () async {
                              await ctrl.setShuffle(true);
                              await ctrl.playFromList(list, 0, context: ctx);
                            },
                          ),
                          PlayCircleButton(
                            size: 44,
                            onPressed: () =>
                                ctrl.playFromList(list, 0, context: ctx),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemExtent: trackRowExtentOf(context, compact),
                        itemCount: list.length,
                        itemBuilder: (_, i) => LiveTrackRow(
                          track: list[i],
                          compact: compact,
                          onTap: () => ctrl.playFromList(list, i, context: ctx),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
