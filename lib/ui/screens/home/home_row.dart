import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/player_providers.dart';
import '../../theme/tokens.dart';

/// A cover, two lines and an optional bar: the row of Home lists.
class HomeRow extends StatelessWidget {
  const HomeRow({
    super.key,
    required this.cover,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.bar,
  });

  final Widget cover;
  final String title;
  final String? subtitle;
  final Widget? bar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CcDims.rList),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              cover,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyLarge,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium,
                      ),
                    if (bar != null) ...[const SizedBox(height: 6), bar!],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeIconCover extends StatelessWidget {
  const HomeIconCover(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: context.cc.surface2,
      borderRadius: BorderRadius.circular(CcDims.rList),
    ),
    child: Icon(icon, color: context.cc.accent),
  );
}

/// The 2 px progress line under a row.
class HomeBar extends StatelessWidget {
  const HomeBar(this.fraction, {super.key});
  final double fraction;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(1),
    child: LinearProgressIndicator(
      value: fraction,
      minHeight: 2,
      color: context.cc.accent,
      backgroundColor: context.cc.surface3,
    ),
  );
}

/// Only this widget follows the position tick, not the whole list.
class HomePlayingBar extends ConsumerWidget {
  const HomePlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value;
    return HomeBar(
      dur == null || dur.inMilliseconds <= 0
          ? 0
          : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
    );
  }
}
