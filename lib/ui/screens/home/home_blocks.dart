import '../../../providers/track_ops.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../data/repositories/home_sections.dart';
import '../../../data/repositories/track_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/memory_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/radio_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/section_header.dart';
import '../library/all_tracks_screen.dart';
import '../library/favorites_screen.dart';
import '../playlists/playlists_screen.dart';
import '../radio/radio_screen.dart';
import 'cover_fan.dart';
import '../../widgets/cc_app_bar.dart';

/// «Casuale su tutto»: shuffle on, then the whole library from a random track.
class ShuffleHero extends ConsumerWidget {
  const ShuffleHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final totals = ref.watch(memoryTotalsProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CcDims.margin,
        CcDims.gap8,
        CcDims.margin,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unbounded 28 on one line, shrunk rather than wrapped.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l.homeShuffleAll, style: theme.displaySmall),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  totals == null
                      ? ''
                      : l.homeShuffleAllSub(
                          l.tracksCount(totals.trackCount),
                          l.hoursCount(totals.durationMs ~/ 3600000),
                        ),
                  style: theme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: l.homeShuffleAll,
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: cc.accent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _play(ref),
                      child: SizedBox.square(
                        dimension: 48,
                        child: Icon(Icons.shuffle, color: cc.onAccent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _play(WidgetRef ref) async {
    final ctrl = ref.read(playerControllerProvider);
    try {
      // The whole library, not what the «Tutti i brani» search shows.
      final tracks = await ref.read(trackOpsProvider).all();
      if (tracks.isEmpty) return;
      await ctrl.setShuffle(true);
      await ctrl.playAll(
        tracks,
        context: const PlayContext(PlayContextKind.library),
      );
    } on Object catch (e, st) {
      AppLog.e('shuffle everything failed', e, st);
    }
  }
}

/// Favourites, Playlist and Radio, each with how many it holds.
class ShortcutsRow extends ConsumerWidget {
  const ShortcutsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    int count<T>(AsyncValue<List<T>> v) => v.value?.length ?? 0;
    final cc = context.cc;
    Widget tile(String label, int n, Widget page, {bool first = false}) =>
        Expanded(
          child: _Shortcut(
            label: label,
            count: n,
            border: first ? null : BorderSide(color: cc.separator),
            onTap: () => ShellNav.open<void>(context, page),
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(
        CcDims.margin,
        CcDims.gap8,
        CcDims.margin,
        0,
      ),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: cc.separator)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            tile(
              l.navFavorites,
              count(ref.watch(tracksProvider(true))),
              const FavoritesScreen(),
              first: true,
            ),
            tile(
              l.navPlaylists,
              count(ref.watch(playlistsProvider)),
              Scaffold(
                appBar: CcAppBar(title: l.navPlaylists),
                body: const PlaylistsScreen(),
              ),
            ),
            tile(
              l.radioTitle,
              count(ref.watch(savedRadiosProvider)),
              const RadioScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.count,
    required this.onTap,
    this.border,
  });

  final String label;
  final int count;
  final BorderSide? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            vertical: CcDims.gap12,
            horizontal: CcDims.gap4,
          ),
          decoration: BoxDecoration(
            border: border == null ? null : Border(left: border!),
          ),
          // Count and label side by side; the label wraps at large text.
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$count', style: theme.bodyLarge),
                TextSpan(text: '  $label'),
              ],
            ),
            textAlign: TextAlign.center,
            style: theme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

/// «Aggiunti da poco»: the fan, and «Mostra tutti» for the full list by date.
class AddedLately extends ConsumerWidget {
  const AddedLately({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final albums = recentlyAddedAlbums(
      ref.watch(albumsProvider).value ?? const [],
      limit: 5,
    );
    if (albums.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SectionHeader(
          l.homeAddedLately,
          actionLabel: l.showAll,
          onAction: () {
            ref
                .read(trackQueryProvider(false).notifier)
                .update((q) => q.copyWith(sort: SortOption.addedAt, text: ''));
            ShellNav.open<void>(context, const AllTracksScreen());
          },
        ),
        CoverFan(albums: albums),
      ],
    );
  }
}
