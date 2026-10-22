import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/repositories/library_queries.dart';
import '../../../l10n/l10n_ext.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/motion.dart';
import '../library/album_detail_screen.dart';

const _maxCovers = 5;
const _maxTilt = 8 * math.pi / 180;
const _gap = 8.0;

/// Up to five albums as overlapping, tilted covers. The first tap (or the
/// mouse pointer) spreads them into a row; a tap on a spread cover opens that
/// album. Only transforms move, on their own layer.
class CoverFan extends StatefulWidget {
  const CoverFan({super.key, required this.albums});

  final List<AlbumSummary> albums;

  @override
  State<CoverFan> createState() => _CoverFanState();
}

class _CoverFanState extends State<CoverFan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _open = false;
  bool _byHover = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c.duration = ccDuration(context, Motion.pulse);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _setOpen(bool open, {bool hover = false}) {
    setState(() {
      _open = open;
      _byHover = open && hover;
    });
    open ? _c.forward() : _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final albums = widget.albums.take(_maxCovers).toList();
    if (albums.isEmpty) return const SizedBox.shrink();
    final n = albums.length;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final size = math.min(w * 0.42, 168.0);
          final spread = math.min(size, (w - _gap * (n - 1)) / n);
          return MouseRegion(
            onEnter: (_) => _setOpen(true, hover: true),
            onExit: (_) {
              if (_byHover) _setOpen(false);
            },
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = Motion.curve.transform(_c.value);
                  final fan = SizedBox(
                    height: size + 24,
                    width: w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < n; i++)
                          _cover(albums[i], i, n, size, spread, t),
                      ],
                    ),
                  );
                  return _open
                      ? fan
                      : Semantics(
                          button: true,
                          label: l.homeFanOpen,
                          excludeSemantics: true,
                          child: fan,
                        );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cover(
    AlbumSummary a,
    int i,
    int n,
    double size,
    double spread,
    double t,
  ) {
    final mid = i - (n - 1) / 2;
    final dx = _lerp(mid * size * 0.28, mid * (spread + _gap), t);
    final tilt = n == 1 ? 0.0 : _lerp(_maxTilt * (2 * i / (n - 1) - 1), 0, t);
    final scale = _lerp(1, spread / size, t);
    final m = Matrix4.translationValues(dx, 0, 0)
      ..rotateZ(tilt)
      ..scaleByDouble(scale, scale, 1, 1);
    return Transform(
      alignment: Alignment.center,
      transform: m,
      child: GestureDetector(
        key: ValueKey('fan-cover-$i'),
        onTap: () => _open
            ? ShellNav.open<void>(context, AlbumDetailScreen(album: a))
            : _setOpen(true),
        child: Semantics(
          button: _open,
          label: _open ? a.title : null,
          child: CoverImage(
            coverKey: a.coverKey,
            size: size,
            radius: CcDims.rGrid,
          ),
        ),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
