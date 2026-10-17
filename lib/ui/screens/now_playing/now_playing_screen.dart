import '../../../core/platform.dart';
import 'package:flutter/material.dart';
import '../car/car_mode_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/library_queries.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/player_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_backdrop.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/favorite_actions.dart';
import '../../widgets/mini_player.dart' show kPlayerCoverHero;
import '../../widgets/track_actions.dart';
import '../library/artist_screen.dart';
import 'now_playing_cards.dart';
import 'now_playing_controls.dart';

const _wideBreakpoint = 900.0;
const _closeDistance = 120.0;
const _closeVelocity = 700.0;

/// «In riproduzione da»: the name of where the queue came from.
String? playContextName(AppLocalizations l, PlayContext? c) {
  if (c == null) return null;
  return switch (c.kind) {
    PlayContextKind.album ||
    PlayContextKind.artist ||
    PlayContextKind.playlist ||
    PlayContextKind.podcast => c.name,
    PlayContextKind.favorites => l.navFavorites,
    PlayContextKind.library => l.allTracks,
    PlayContextKind.search => l.playContextSearch,
  };
}

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  double _dy = 0;
  bool _dragging = false;

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_dy > _closeDistance || v > _closeVelocity) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _dragging = false;
      _dy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final track =
        ref.watch(liveCurrentTrackProvider).value ??
        ref.watch(currentTrackProvider).value;
    final cc = context.cc;
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: cc.bg,
      body: CoverBackdrop(
        coverKey: track?.coverKey,
        child: SafeArea(
          child: AnimatedContainer(
            duration: _dragging || reduce ? Duration.zero : CcMotion.sheet,
            transform: Matrix4.translationValues(0, _dy, 0),
            child: track == null
                ? _Empty(onClose: () => Navigator.of(context).maybePop())
                : LayoutBuilder(
                    builder: (context, c) {
                      final player = _Player(
                        track: track,
                        onDragUpdate: (d) => setState(() {
                          _dragging = true;
                          _dy = (_dy + d.delta.dy).clamp(0.0, 600.0);
                        }),
                        onDragEnd: _onDragEnd,
                      );
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 560,
                                  ),
                                  child: player,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 380,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  16,
                                  16,
                                  16,
                                ),
                                children: [
                                  LyricsCard(track: track),
                                  const SizedBox(height: 12),
                                  InfoCard(track: track),
                                  const SizedBox(height: 12),
                                  const UpNextCard(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(height: c.maxHeight, child: player),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              CcDims.margin,
                              0,
                              CcDims.margin,
                              24,
                            ),
                            sliver: SliverList.list(
                              children: [
                                LyricsCard(track: track),
                                const SizedBox(height: 12),
                                InfoCard(track: track),
                                const SizedBox(height: 12),
                                const UpNextCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: context.l10n.back,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: onClose,
        ),
      ),
      Expanded(child: Center(child: Text(context.l10n.nothingPlaying))),
    ],
  );
}

/// Header, cover, title row, seek, controls and the bottom row.
class _Player extends ConsumerWidget {
  const _Player({
    required this.track,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Track track;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  void _openArtist(BuildContext context, WidgetRef ref) {
    // The page only needs the same key `watchArtists` groups by.
    final key = (track.artist ?? '').trim().toLowerCase();
    final artist = ArtistSummary(
      key: key,
      name: track.artist,
      trackCount: 0,
      albumCount: 0,
    );
    ShellNav.openInLibrary(context, ref, ArtistDetailScreen(artist: artist));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final ctx = playContextName(l, ref.watch(playContextProvider));
    final ctrl = ref.read(playerControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    tooltip: l.back,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 32,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ctx == null ? l.nowPlaying : l.playingFrom,
                          style: theme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: cc.textMuted,
                          ),
                        ),
                        if (ctx != null)
                          Text(
                            ctx,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cc.text,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isDesktop)
                    IconButton(
                      tooltip: l.carMode,
                      icon: const Icon(Icons.directions_car_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const CarModeScreen()),
                      ),
                    ),
                  IconButton(
                    tooltip: l.moreActions,
                    icon: const Icon(Icons.more_horiz_rounded),
                    onPressed: () => showTrackActions(context, ref, track),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: onDragUpdate,
              onVerticalDragEnd: onDragEnd,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -300 && ctrl.hasNext) ctrl.next();
                if (v > 300) ctrl.previous();
              },
              child: LayoutBuilder(
                builder: (_, c) => Center(
                  child: CoverImage(
                    coverKey: track.coverKey,
                    size: (c.biggest.shortestSide).clamp(80.0, 460.0),
                    radius: CcDims.rGrid,
                    heroTag: kPlayerCoverHero,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleLarge,
                    ),
                    InkWell(
                      onTap: () => _openArtist(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          track.artist ?? l.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyLarge?.copyWith(color: cc.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: track.isFavorite ? l.removeFromFavorites : l.favorite,
                onPressed: () => toggleFavorite(context, ref, track),
                icon: Icon(
                  track.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: track.isFavorite ? cc.accent : cc.text,
                ),
              ),
            ],
          ),
          NpSeekRow(track: track),
          const SizedBox(height: 8),
          const NpControls(),
          const NpBottomRow(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
