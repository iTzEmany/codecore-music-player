import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final tint = resolvedHeroTint(context, ref, coverKey);
    return Stack(children: [
      Positioned.fill(child: ColoredBox(color: cc.bg)),
      Positioned.fill(
        child: FractionallySizedBox(
          alignment: Alignment.topCenter,
          heightFactor: 0.6,
          child: AnimatedContainer(
            duration: ccDuration(context, CcMotion.color),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tint, cc.bg],
              ),
            ),
          ),
        ),
      ),
      Positioned.fill(child: child),
    ]);
  }
}
