import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/theme/background_image.dart';
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

/// Makes (once) the blurred copy of a background picture; swapped in tests.
typedef BackgroundBlurrer = Future<String?> Function(String path, double blur);

/// Behind every page: the gradient or the picture of the theme in use. Pages
/// are see-through while one is active (see `buildThemeFromColors`). A blurred
/// picture is drawn from its blurred copy: nothing is filtered on screen.
class AppBackground extends StatefulWidget {
  const AppBackground({
    super.key,
    required this.colors,
    required this.background,
    required this.child,
    this.blurrer = blurredBackground,
  });

  final CcColors colors;
  final ThemeBackground background;
  final Widget child;
  final BackgroundBlurrer blurrer;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  /// The blurred copy on screen; the last one stays while the next is made
  /// (dragging the slider), the plain colour before the first.
  String? _blurred;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(AppBackground old) {
    super.didUpdateWidget(old);
    final b = widget.background, o = old.background;
    if (b.imagePath != o.imagePath || b.blur.round() != o.blur.round()) _resolve();
  }

  void _resolve() {
    final path = widget.background.imagePath;
    final blur = widget.background.blur.round();
    final id = ++_request;
    if (path == null || blur <= 0) {
      _blurred = null;
      return;
    }
    widget.blurrer(path, blur.toDouble()).then((out) {
      if (mounted && id == _request) setState(() => _blurred = out);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.background.isCustom) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: ColoredBox(color: widget.colors.bg)),
        Positioned.fill(child: _layer(context)),
        widget.child,
      ],
    );
  }

  Widget _layer(BuildContext context) {
    final background = widget.background;
    final gradient = themeGradient(widget.colors, background);
    if (gradient != null) {
      return DecoratedBox(decoration: BoxDecoration(gradient: gradient));
    }
    final path = background.blur.round() > 0 ? _blurred : background.imagePath;
    if (path == null) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        // A file that is gone or damaged leaves the plain colour behind.
        Image.file(
          File(path),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        if (background.dim > 0)
          ColoredBox(color: Colors.black.withValues(alpha: background.dim)),
      ],
    );
  }
}
