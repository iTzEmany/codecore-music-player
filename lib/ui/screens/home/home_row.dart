import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/progress_frame.dart';

/// Cover side inside the 52 dp frame of a row.
const kHomeCover = 44.0;

/// A cover in a 52 dp frame, two lines and a 1 dp separator ("Quaderno" row).
/// [progress] draws the 2 dp ring around the cover; [now] marks the playing
/// row (full ring, title in the soft accent).
class HomeRow extends StatelessWidget {
  const HomeRow({
    super.key,
    required this.cover,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.progress,
    this.now = false,
    this.last = false,
  });

  final Widget cover;
  final String title;
  final String? subtitle;
  final double? progress;
  final bool now, last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final cc = context.cc;
    final framed = Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CcDims.rList),
        child: SizedBox.square(dimension: kHomeCover, child: cover),
      ),
    );
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: CcDims.margin,
            vertical: 6,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  if (now || progress != null)
                    ProgressFrame(
                      size: 52,
                      progress: now ? null : progress,
                      child: framed,
                    )
                  else
                    SizedBox.square(dimension: 52, child: framed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyLarge?.copyWith(
                            color: now ? cc.accentSoft : null,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!last)
                Positioned(
                  left: 64,
                  right: 0,
                  bottom: -6,
                  child: Divider(height: 1, thickness: 1, color: cc.separator),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder cover with an icon.
class HomeIconCover extends StatelessWidget {
  const HomeIconCover(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    color: context.cc.surface3,
    child: Icon(icon, color: context.cc.accentSoft),
  );
}
