import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

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
                  now
                      ? HomePlayingFrame(child: framed)
                      : HomeFrame(progress: progress, child: framed),
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
                  child: Divider(height: 1, thickness: 1, color: cc.surface3),
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

/// 52 dp square holding [child]; with [progress] a 2 dp rounded-square ring
/// (track in s3, arc in the accent) runs clockwise from the top.
class HomeFrame extends StatelessWidget {
  const HomeFrame({super.key, required this.child, this.progress});

  final Widget child;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return SizedBox.square(
      dimension: 52,
      child: progress == null
          ? child
          : CustomPaint(
              foregroundPainter: _FramePainter(
                progress!,
                cc.accent,
                cc.surface3,
              ),
              child: child,
            ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.fraction, this.arc, this.rest);

  final double fraction;
  final Color arc, rest;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(7),
        ),
      );
    if (fraction < 1) canvas.drawPath(path, line..color = rest);
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * fraction), line..color = arc);
    }
  }

  @override
  bool shouldRepaint(_FramePainter o) =>
      o.fraction != fraction || o.arc != arc || o.rest != rest;
}

/// The playing row: a full ring (a state, not the playhead).
class HomePlayingFrame extends StatelessWidget {
  const HomePlayingFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => HomeFrame(progress: 1, child: child);
}
