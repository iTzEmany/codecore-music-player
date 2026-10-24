import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_providers.dart';
import '../theme/cover_tint.dart';
import '../theme/tokens.dart';

/// Vertical gradient tint → background over the top 60 % of the page.
class CoverBackdrop extends ConsumerWidget {
  const CoverBackdrop({super.key, required this.coverKey, required this.child});

  final String? coverKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    // The theme's own background (gradient or picture) instead of the tint.
    final bg = ref.watch(themeBackgroundProvider);
    if (bg.isCustom && !bg.coverBackdrop) return child;
    final tint = resolvedHeroTint(context, ref, coverKey);
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: cc.bg)),
        Positioned.fill(
          child: FractionallySizedBox(
            alignment: Alignment.topCenter,
            heightFactor: 0.6,
            child: RepaintBoundary(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: tint),
                duration: ccDuration(context, CcMotion.page),
                builder: (context, c, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [c ?? tint, cc.bg],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
