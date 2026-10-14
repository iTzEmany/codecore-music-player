import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../providers/player_providers.dart';
import 'cover_image.dart';
import 'format_utils.dart';

/// Fixed-height row; pair with `itemExtent` in the list.
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    this.onMore,
    this.compact = false,
  });

  final Track track;
  final bool isCurrent, isPlaying, compact;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (track.artist != null) track.artist!,
      if (track.album != null) track.album!,
    ].join(' • ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          CoverImage(coverKey: track.coverKey, size: compact ? 36 : 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isCurrent ? scheme.primary : null,
                        fontWeight: isCurrent ? FontWeight.w600 : null)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(isPlaying ? Icons.equalizer : Icons.pause,
                  size: 18, color: scheme.primary),
            ),
          Text(formatDuration(track.durationMs),
              style: Theme.of(context).textTheme.bodySmall),
          if (track.isFavorite)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.favorite, size: 16, color: scheme.primary),
            ),
          if (onMore != null)
            IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_vert),
                visualDensity: VisualDensity.compact),
        ]),
      ),
    );
  }
}

/// Rebuilds only when this row's "current/playing" state changes.
class LiveTrackTile extends ConsumerWidget {
  const LiveTrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onMore,
    this.compact = false,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
        currentTrackProvider.select((t) => t.value?.id == track.id));
    final playing = isCurrent && (ref.watch(isPlayingProvider).value ?? false);
    return TrackTile(
      track: track,
      isCurrent: isCurrent,
      isPlaying: playing,
      onTap: onTap,
      onMore: onMore,
      compact: compact,
    );
  }
}
