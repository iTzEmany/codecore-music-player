import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/player_providers.dart';
import '../../core/platform.dart';
import '../screens/now_playing/now_playing_screen.dart';
import '../strings_it.dart';
import 'cover_image.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider).value;
    if (track == null) return const SizedBox.shrink();
    final playing = ref.watch(isPlayingProvider).value ?? false;
    final ctrl = ref.read(playerControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => const NowPlayingScreen(),
          transitionsBuilder: (_, anim, _, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        )),
        onHorizontalDragEnd: isAndroid
            ? (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) ctrl.next();
                if (v > 200) ctrl.previous();
              }
            : null,
        child: SizedBox(
          height: 64,
          child: Column(children: [
            const _MiniProgress(),
            Expanded(
              child: Row(children: [
                const SizedBox(width: 12),
                CoverImage(coverKey: track.coverKey, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(track.artist ?? S.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: ctrl.togglePlayPause,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                    onPressed: ctrl.next, icon: const Icon(Icons.skip_next)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MiniProgress extends ConsumerWidget {
  const _MiniProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value ?? Duration.zero;
    final value = dur.inMilliseconds <= 0
        ? 0.0
        : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
    return LinearProgressIndicator(value: value, minHeight: 2);
  }
}
