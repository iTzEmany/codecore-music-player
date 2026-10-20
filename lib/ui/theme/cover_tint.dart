import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_log.dart';
import '../widgets/cover_image.dart';
import 'tokens.dart';

/// Average colour of an RGBA buffer, weighted by saturation and ignoring
/// near-black / near-white pixels; null when nothing useful is left.
Color? tintFromPixels(Uint8List rgba) {
  var r = 0.0, g = 0.0, b = 0.0, w = 0.0;
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 128) continue;
    final pr = rgba[i] / 255, pg = rgba[i + 1] / 255, pb = rgba[i + 2] / 255;
    final hi = [pr, pg, pb].reduce((a, c) => a > c ? a : c);
    final lo = [pr, pg, pb].reduce((a, c) => a < c ? a : c);
    final light = (hi + lo) / 2;
    if (light < 0.08 || light > 0.94) continue;
    final sat = hi == lo ? 0.0 : (hi - lo) / (1 - (2 * light - 1).abs());
    final weight = 0.05 + sat;
    r += pr * weight;
    g += pg * weight;
    b += pb * weight;
    w += weight;
  }
  if (w <= 0) return null;
  return Color.from(alpha: 1, red: r / w, green: g / w, blue: b / w);
}

/// Highest luminance that keeps the primary text (`#F4F0FA`) at ≥ 7:1.
const _maxHeroLuminance = 0.08;

/// Lowest luminance that keeps the dark text of the light theme (`#1B1427`)
/// at ≥ 7:1.
const _minLightHeroLuminance = 0.42;

/// Pulls [c] towards the base violet and clamps lightness to at most 0.30
/// (at least 0.16 unless a bright hue like yellow needs to go darker to keep
/// the primary text at ≥ 7:1 contrast). With [light] it is the other way
/// round: pale, lightness at least 0.80, for the dark text of the light theme.
Color heroTint(Color c, Color base, {bool light = false}) {
  final mixed = Color.lerp(c, base, 0.45)!;
  final hsl = HSLColor.fromColor(mixed);
  if (light) {
    final pale = hsl.withSaturation(hsl.saturation.clamp(0.0, 0.7));
    var l = hsl.lightness.clamp(0.80, 0.92);
    var out = pale.withLightness(l).toColor();
    while (out.computeLuminance() < _minLightHeroLuminance && l < 0.98) {
      l += 0.01;
      out = pale.withLightness(l).toColor();
    }
    return out;
  }
  var l = hsl.lightness.clamp(0.16, 0.30);
  var out = hsl.withLightness(l).toColor();
  while (out.computeLuminance() > _maxHeroLuminance && l > 0.02) {
    l -= 0.01;
    out = hsl.withLightness(l).toColor();
  }
  return out;
}

/// Tint of one cover, computed once per key and kept alive.
final coverTintProvider = FutureProvider.family<Color?, String>((
  ref,
  coverKey,
) async {
  ref.keepAlive();
  // 24 px are enough: the thumbnail is read, not the original.
  final file = ref.watch(coverThumbProvider(coverKey));
  if (file == null) return null;
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 24);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    frame.image.dispose();
    codec.dispose();
    if (data == null) return null;
    return tintFromPixels(data.buffer.asUint8List());
  } on Object catch (e, st) {
    AppLog.w('cover tint failed', e, st);
    return null;
  }
});

/// The colour behind a cover: its tint pulled towards the theme's violet,
/// or `heroBase` while loading / without cover.
Color resolvedHeroTint(BuildContext context, WidgetRef ref, String? coverKey) {
  final cc = context.cc;
  final base = cc.heroBase;
  if (coverKey == null) return base;
  final tint = ref.watch(coverTintProvider(coverKey)).value;
  return tint == null ? base : heroTint(tint, base, light: cc.isLight);
}
