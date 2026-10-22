import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../services/jam/jam_models.dart';
import '../../theme/tokens.dart';
import '../../widgets/play_buttons.dart';
import '../../widgets/ring_progress.dart';
import 'jam_outputs_sheet.dart';
import 'jam_parts.dart';
import 'jam_seek_bar.dart';

/// The shared player of the Jam: cover in a full ring, title, seek, controls.
class JamPlayerCard extends ConsumerWidget {
  const JamPlayerCard({super.key, required this.state});

  final JamUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final jam = state.jam!;
    final cur = jam.current;
    final ctrl = ref.read(jamProvider.notifier);
    final ring = (MediaQuery.sizeOf(context).shortestSide * 0.4).clamp(
      120.0,
      240.0,
    );
    final inner = RingProgress.innerSize(ring, stroke: 4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
      child: Column(
        children: [
          RingProgress(
            size: ring,
            stroke: 4,
            live: true,
            child: JamCover(item: cur, size: inner, radius: inner / 2),
          ),
          const SizedBox(height: 12),
          Text(
            cur?.title ?? l.jamNothingPlaying,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.titleLarge,
          ),
          Text(
            cur?.artist ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.bodyMedium?.copyWith(color: cc.textMuted),
          ),
          JamSeekBar(jam: jam, onSeek: (ms) => ctrl.send(JamCommand.seek(ms))),
          // Equal side slots: Play stays at the centre for host and guest.
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: l.jamOutputsAndSync,
                    icon: Icon(
                      Icons.speaker_group_outlined,
                      color: cc.textMuted,
                    ),
                    onPressed: () => JamOutputsSheet.show(context),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PlayCircleButton(
                size: 56,
                playing: jam.playing,
                onPressed: cur == null
                    ? null
                    : () => ctrl.send(
                        jam.playing
                            ? const JamCommand.pause()
                            : const JamCommand.play(),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: state.isHost
                      ? IconButton(
                          tooltip: l.nextTrack,
                          iconSize: 32,
                          icon: const Icon(Icons.skip_next_rounded),
                          onPressed: cur == null
                              ? null
                              : () => ctrl.send(const JamCommand.next()),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
