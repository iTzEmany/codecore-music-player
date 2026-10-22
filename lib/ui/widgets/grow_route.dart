import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'motion.dart';

const _duration = Duration(milliseconds: 550);

/// Opens a page growing out of [from] (the dock's global rect): a rounded clip
/// widens to the whole screen while the page fades in over the first 40 %.
/// With [reduceMotion] («Riduci animazioni», read when the route is pushed) the
/// route takes no time and the page is simply there.
Route<T> growRoute<T>({
  required Rect from,
  required WidgetBuilder builder,
  bool reduceMotion = false,
}) => PageRouteBuilder<T>(
  transitionDuration: reduceMotion ? Duration.zero : _duration,
  reverseTransitionDuration: reduceMotion ? Duration.zero : _duration,
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animation, _, child) {
    if (ccDuration(context, _duration) == Duration.zero) {
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
