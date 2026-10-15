import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../services/jam/jam_models.dart';
import '../../theme/tokens.dart';
import '../../widgets/play_buttons.dart';
import 'jam_outputs_sheet.dart';
import 'jam_seek_bar.dart';

/// The shared player of the Jam: title, seek with times, play / next.
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: CcDims.margin),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: cc.surface1,
        borderRadius: BorderRadius.circular(CcDims.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cur == null ? l.jamNothingPlaying : l.jamNowPlaying,
            style: theme.labelSmall?.copyWith(color: cc.textMuted),
          ),
          if (cur != null) ...[
            Text(
              cur.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.titleLarge,
            ),
            Text(
              cur.artist ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium,
            ),
          ],
          JamSeekBar(jam: jam, onSeek: (ms) => ctrl.send(JamCommand.seek(ms))),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Same width as the «next» button: Play sits in the middle.
              if (state.isHost) const SizedBox(width: 48),
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
              if (state.isHost)
                IconButton(
                  tooltip: l.nextTrack,
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: cur == null
                      ? null
                      : () => ctrl.send(const JamCommand.next()),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => JamOutputsSheet.show(context),
              icon: const Icon(Icons.speaker_group_outlined, size: 20),
              label: Text(l.jamOutputsAndSync),
            ),
          ),
        ],
      ),
    );
  }
}
