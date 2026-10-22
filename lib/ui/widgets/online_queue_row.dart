import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/player_providers.dart';
import '../theme/tokens.dart';
import 'now_playing_bars.dart';
import 'track_actions.dart';
import 'radio_now.dart';
import 'track_art.dart';

/// «Suggerito»: the small cloud and the word, shown wherever a streamed
/// entry is listed.
class SuggestedMarker extends StatelessWidget {
  const SuggestedMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_outlined, size: 14, color: cc.accent),
        const SizedBox(width: 4),
        Text(
          context.l10n.suggestedBadge,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cc.accent),
        ),
      ],
    );
  }
}

/// A streamed entry in a list (the queue): thumbnail, title, artist and the
/// «Suggerito» marker. Same height as a queue row; reorders with the handle
/// when [reorderIndex] is given. Its menu has only the online actions.
class OnlineQueueRow extends ConsumerWidget {
  const OnlineQueueRow({
    super.key,
    required this.track,
    required this.onTap,
    this.reorderIndex,
  });

  final Track track;
  final VoidCallback onTap;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final l = context.l10n;
    final isCurrent = ref.watch(currentTrackProvider.select((t) => t.value?.id == track.id));
    final playing = isCurrent && (ref.watch(isPlayingProvider).value ?? false);
    final i = reorderIndex;
    final radio = radioOfTrack(ref, track);
    return InkWell(
      onTap: onTap,
      onLongPress: () => showTrackActions(context, ref, track),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                TrackArt(track: track, size: 48),
                if (isCurrent)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cc.bg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(CcDims.rList),
                    ),
                    alignment: Alignment.center,
                    child: NowPlayingBars(playing: playing, size: 19),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.bodyLarge),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (radio != null)
                        Icon(Icons.circle, size: 8, color: cc.accent)
                      else
                        const SuggestedMarker(),
                      if (radio != null) ...[
                        const SizedBox(width: 6),
                        Text(l.radioLive, style: theme.bodySmall),
                      ] else if (track.artist != null) ...[
                        Text(' · ', style: theme.bodySmall),
                        Flexible(
                          child: Text(
                            track.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.moreOptions,
              visualDensity: VisualDensity.compact,
              onPressed: () => showTrackActions(context, ref, track),
              icon: Icon(Icons.more_vert_rounded, color: cc.textMuted),
            ),
            if (i != null)
              ReorderableDragStartListener(
                index: i,
                child: Icon(Icons.drag_handle_rounded, color: cc.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}
