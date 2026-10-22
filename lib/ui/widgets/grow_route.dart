import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'motion.dart';

/// Opens a page growing out of [from] (the dock's global rect): a rounded clip
/// widens to the whole screen while the page fades in over the first 40 %.
/// With «Riduci animazioni» the page is simply there.
Route<T> growRoute<T>({required Rect from, required WidgetBuilder builder}) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 550),
  reverseTransitionDuration: const Duration(milliseconds: 550),
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animation, _, child) {
    if (ccDuration(context, const Duration(milliseconds: 550)) == Duration.zero) {
      return child;
    }
    final t = animation.drive(CurveTween(curve: Motion.curve));
    return ClipRRect(
      clipper: _GrowClipper(from, t),
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: const Interval(0, 0.4))),
        child: RepaintBoundary(child: child),
      ),
    );
  },
);

class _GrowClipper extends CustomClipper<RRect> {
  _GrowClipper(this.from, this.t) : super(reclip: t);

  final Rect from;
  final Animation<double> t;

  @override
  RRect getClip(Size size) => RRect.fromRectAndRadius(
    Rect.lerp(from, Offset.zero & size, t.value)!,
    Radius.circular(lerpDouble(CcDims.dockRadius, 0, t.value)!),
  );

  @override
  bool shouldReclip(_GrowClipper old) => old.from != from;
}
