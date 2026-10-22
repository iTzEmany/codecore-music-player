import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../providers/player_providers.dart';
import '../../providers/shuffle_plus_providers.dart';
import '../screens/now_playing/shuffle_plus_sheet.dart';
import '../theme/tokens.dart';
import 'motion.dart';

/// The three-state shuffle button of the players: off, shuffle, Shuffle+
/// (shuffle with a «+»). Tap goes to the next state, long press opens the
/// Shuffle+ settings.
class ShuffleModeButton extends ConsumerWidget {
  const ShuffleModeButton({super.key, this.size = 28, this.dot = true});

  final double size;

  /// The dot under the icon (Now Playing); the desktop bar goes without.
  final bool dot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    final l = context.l10n;
    final mode = ref.watch(shuffleModeProvider);
    final on = mode != ShuffleMode.off;
    final color = on ? cc.accent : cc.textMuted;
    final icon = Icon(Icons.shuffle_rounded, size: size, color: color);
    // The tooltip must not react to a long press (manual trigger: hover only):
    // on touch it would win the gesture and the Shuffle+ sheet never opened.
    return GestureDetector(
      onLongPress: () => showShufflePlusSheet(context),
      child: Tooltip(
        triggerMode: TooltipTriggerMode.manual,
        message: switch (mode) {
          ShuffleMode.off => l.shuffleModeOff,
          ShuffleMode.shuffle => l.shuffleModeOn,
          ShuffleMode.plus => l.shuffleModePlus,
        },
        child: IconButton(
          onPressed: ref.read(playerControllerProvider).cycleShuffle,
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              mode == ShuffleMode.plus
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        icon,
                        Positioned(
                          right: -size * 0.25,
                          top: -size * 0.15,
                          child: Icon(
                            Icons.add_rounded,
                            key: const ValueKey('shuffle-plus-badge'),
                            size: size * 0.6,
                            color: color,
                          ),
                        ),
                      ],
                    )
                  : icon,
              if (dot) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: on ? cc.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// «Casuale» word button of the collection headers: accent while shuffle is
/// on, with the «+» badge in Shuffle+; long press opens the Shuffle+ sheet.
class ShufflePill extends ConsumerWidget {
  const ShufflePill({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    final mode = ref.watch(shuffleModeProvider);
    final color = mode == ShuffleMode.off ? cc.text : cc.accent;
    return PressScale(
      child: GestureDetector(
        onLongPress: () => showShufflePlusSheet(context),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(foregroundColor: color),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.shuffle_rounded, color: color),
              if (mode == ShuffleMode.plus)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Icon(
                    Icons.add_rounded,
                    key: const ValueKey('shuffle-plus-badge'),
                    size: 12,
                    color: color,
                  ),
                ),
            ],
          ),
          label: Text(context.l10n.shuffle),
        ),
      ),
    );
  }
}
