import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The cover of a smart playlist: a tinted square with a spark.
class SmartCover extends StatelessWidget {
  const SmartCover({super.key, required this.size, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? CcDims.rList),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cc.surface3, cc.surface2],
        ),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.45,
        color: cc.accent,
      ),
    );
  }
}
