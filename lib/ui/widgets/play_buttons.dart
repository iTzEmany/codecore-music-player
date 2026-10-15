import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/player_providers.dart';
import '../theme/tokens.dart';

/// Filled amethyst circle with the play/pause glyph.
class PlayCircleButton extends StatelessWidget {
  const PlayCircleButton({
    super.key,
    required this.onPressed,
    this.playing = false,
    this.size = 56,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final bool playing;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final l = context.l10n;
    return Tooltip(
      message: tooltip ?? (playing ? l.pause : l.play),
      child: Material(
        color: cc.accent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: size * 0.6,
              color: cc.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shuffle icon, amethyst with a dot under it while shuffle is on. The state
/// comes from the player unless [active] overrides it.
class ShuffleButton extends ConsumerWidget {
  const ShuffleButton({
    super.key,
    required this.onPressed,
    this.active,
    this.size = 28,
  });

  final VoidCallback? onPressed;
  final bool? active;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    final active = this.active ?? (ref.watch(shuffleProvider).value ?? false);
    return IconButton(
      tooltip: context.l10n.shuffle,
      onPressed: onPressed,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shuffle_rounded,
            size: size,
            color: active ? cc.accent : cc.textMuted,
          ),
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: active ? cc.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
