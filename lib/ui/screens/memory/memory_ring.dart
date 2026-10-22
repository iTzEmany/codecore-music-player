import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/memory/disk_space.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';

/// The logo ring as a gauge: music (accent), other data (muted), free space
/// (the empty track). Without [disk] it is a full music arc and a note.
class MemoryRing extends StatelessWidget {
  const MemoryRing({super.key, required this.musicBytes, required this.disk});

  final int musicBytes;
  final DiskSpace? disk;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= CcDims.wideBreakpoint;
    final size = wide ? 236.0 : 208.0;
    final locale = l.localeName;
    final d = disk;
    final music = formatBytes(musicBytes, locale);
    final total = d == null ? musicBytes : d.totalBytes;
    final fm = total <= 0 ? 1.0 : (musicBytes / total).clamp(0.0, 1.0);
    final other = d == null ? 0 : (d.usedBytes - musicBytes).clamp(0, d.totalBytes);
    final fo = total <= 0 ? 0.0 : other / total;
    final caption = d == null
        ? l.memoryUnavailable
        : l.memoryDeviceLine(
            formatBytes(d.freeBytes, locale),
            formatBytes(d.totalBytes, locale),
          );
    final muted = theme.bodySmall?.copyWith(color: cc.textMuted);
    Widget key(String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: muted),
      ],
    );
    return Semantics(
      container: true,
      label: '$music ${l.memoryOfMusic}. $caption',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _GaugePainter(
                    music: fm,
                    other: fo,
                    musicColor: cc.accent,
                    otherColor: cc.textMuted,
                    trackColor: cc.surface2,
                  ),
                ),
                SizedBox(
                  width: size * 0.62,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(music, maxLines: 1, style: theme.displaySmall),
                        Text(l.memoryOfMusic, maxLines: 1, style: muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(caption, textAlign: TextAlign.center, style: muted),
          if (d != null) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: [
                key(l.memoryMusicLabel, cc.accent),
                key(l.memoryOtherLabel, cc.textMuted),
                key(l.memoryFreeLabel, cc.surface2),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.music,
    required this.other,
    required this.musicColor,
    required this.otherColor,
    required this.trackColor,
  });

  /// Shares of the whole disk, 0..1.
  final double music, other;
  final Color musicColor, otherColor, trackColor;

  static const _stroke = 10.0;
  static const _gap = 40 * math.pi / 180;
  static const _sweep = 2 * math.pi - _gap;
  static const _start = -math.pi / 4 + _gap / 2;
  static const _sep = 4 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final dotR = _stroke * 0.9;
    final r = size.shortestSide / 2 - dotR;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, line..color = trackColor);
    final musicSweep = _sweep * music;
    final otherSweep = _sweep * other - _sep;
    if (otherSweep > 0) {
      canvas.drawArc(
        rect,
        _start + musicSweep + _sep,
        otherSweep,
        false,
        line..color = otherColor,
      );
    }
    if (musicSweep > 0) {
      canvas.drawArc(rect, _start, musicSweep, false, line..color = musicColor);
    }
    if (musicSweep <= 0) return;
    final a = _start + musicSweep;
    canvas.drawCircle(
      c + Offset(math.cos(a), math.sin(a)) * r,
      dotR,
      Paint()..color = musicColor,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter o) =>
      o.music != music ||
      o.other != other ||
      o.musicColor != musicColor ||
      o.otherColor != otherColor ||
      o.trackColor != trackColor;
}
