import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'custom_theme.dart';
import 'tokens.dart';

/// The gradient of [b] from the theme's background to its end colour, or null
/// when [b] is not a gradient.
LinearGradient? themeGradient(CcColors c, ThemeBackground b) {
  final end = b.gradientEnd;
  if (b.kind != ThemeBackgroundKind.gradient || end == null) return null;
  final a = b.angle * math.pi / 180;
  // 0 is towards the top, 90 towards the right, 180 towards the bottom.
  final dx = math.sin(a), dy = -math.cos(a);
  return LinearGradient(
    begin: Alignment(-dx, -dy),
    end: Alignment(dx, dy),
    colors: [c.bg, end],
  );
}

/// Behind every page: the gradient or the picture of the theme in use. Pages
/// are see-through while one is active (see `buildThemeFromColors`).
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.colors,
    required this.background,
    required this.child,
  });

  final CcColors colors;
  final ThemeBackground background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!background.isCustom) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: ColoredBox(color: colors.bg)),
        Positioned.fill(child: _layer(context)),
        child,
      ],
    );
  }

  Widget _layer(BuildContext context) {
    final gradient = themeGradient(colors, background);
    if (gradient != null) {
      return DecoratedBox(decoration: BoxDecoration(gradient: gradient));
    }
    final path = background.imagePath;
    if (path == null) return const SizedBox.shrink();
    // A file that is gone or damaged leaves the plain colour behind.
    Widget image = Image.file(
      File(path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    if (background.blur > 0) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: background.blur,
          sigmaY: background.blur,
          tileMode: TileMode.clamp,
        ),
        child: image,
      );
    }
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (background.dim > 0)
            ColoredBox(color: Colors.black.withValues(alpha: background.dim)),
        ],
      ),
    );
  }
}
