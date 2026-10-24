import 'package:flutter/material.dart';

/// Visual tokens of docs/fase-11 («Sistema visivo»). Widgets read them through
/// `context.cc`; no hex literals outside this file.
@immutable
class CcColors extends ThemeExtension<CcColors> {
  const CcColors({
    required this.bg,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.heroBase,
    required this.error,
    this.isLight = false,
  });

  final Color bg, surface1, surface2, surface3;
  final Color accent, accentSoft, onAccent;
  final Color text, textMuted, textFaint;
  final Color heroBase, error;

  /// A light palette: dark text on light surfaces.
  final bool isLight;

  static const notte = CcColors(
    bg: Color(0xFF07050C),
    surface1: Color(0xFF120E1C),
    surface2: Color(0xFF1D1630),
    surface3: Color(0xFF2A2140),
    accent: Color(0xFFA06BFF),
    accentSoft: Color(0xFFD9C8FF),
    onAccent: Color(0xFF12081F),
    text: Color(0xFFF4F0FA),
    textMuted: Color(0xFFA79DB8),
    textFaint: Color(0xFF6E6680),
    heroBase: Color(0xFF3B1F70),
    error: Color(0xFFFF6B81),
  );

  static const oled = CcColors(
    bg: Color(0xFF000000),
    surface1: Color(0xFF120E1C),
    surface2: Color(0xFF1D1630),
    surface3: Color(0xFF2A2140),
    accent: Color(0xFFA06BFF),
    accentSoft: Color(0xFFD9C8FF),
    onAccent: Color(0xFF12081F),
    text: Color(0xFFF4F0FA),
    textMuted: Color(0xFFA79DB8),
    textFaint: Color(0xFF6E6680),
    heroBase: Color(0xFF3B1F70),
    error: Color(0xFFFF6B81),
  );

  static const chiaro = CcColors(
    bg: Color(0xFFFAF8FD),
    surface1: Color(0xFFF2EEF9),
    surface2: Color(0xFFE9E3F4),
    surface3: Color(0xFFDAD1EB),
    accent: Color(0xFF6A35D8),
    accentSoft: Color(0xFF5B2BBE),
    onAccent: Color(0xFFFFFFFF),
    text: Color(0xFF1B1427),
    textMuted: Color(0xFF5C5170),
    textFaint: Color(0xFF8C829E),
    heroBase: Color(0xFFE6DAFA),
    error: Color(0xFFC8203B),
    isLight: true,
  );

  @override
  CcColors copyWith({Color? bg, Color? accent}) => CcColors(
    bg: bg ?? this.bg,
    surface1: surface1,
    surface2: surface2,
    surface3: surface3,
    accent: accent ?? this.accent,
    accentSoft: accentSoft,
    onAccent: onAccent,
    text: text,
    textMuted: textMuted,
    textFaint: textFaint,
    heroBase: heroBase,
    error: error,
    isLight: isLight,
  );

  @override
  CcColors lerp(ThemeExtension<CcColors>? other, double t) =>
      other is CcColors && t >= 0.5 ? other : this;
}

extension CcContext on BuildContext {
  CcColors get cc => Theme.of(this).extension<CcColors>() ?? CcColors.notte;
}

/// Radii, spacing and sizes shared by every screen.
abstract final class CcDims {
  static const rList = 4.0; // covers in lists, tags
  static const rGrid = 8.0; // grid covers, tiles, menus, snackbars
  static const rCard = 12.0; // mini-player, cards
  static const rSheet = 16.0; // top edge of sheets and dialogs
  static const margin = 16.0;

  static const miniPlayerHeight = 56.0;
  static const dockRadius = 28.0;
  static const dockMargin = 10.0;
  static const bottomBarHeight = 56.0;
  static const desktopPlayerBarHeight = 80.0;
  static const sidebarWidth = 240.0;
  static const sidebarCollapsedWidth = 72.0;
  static const sidePanelWidth = 320.0;
  static const wideBreakpoint = 840.0;

  /// Tablets, unfolded foldables and wide windows: the right panel opens by
  /// itself and is wider, and grids and shelves hold more.
  static const xlBreakpoint = 1200.0;
  static const sidePanelWidthXl = 360.0;
}

/// The one motion scale (D-23): press 120, enter 180, sheet 250, page/hero 320
/// ms; ease-out-cubic in, ease-in-cubic out. Durations go through [ccDuration]
/// (zero with «Riduci animazioni»).
abstract final class CcMotion {
  static const press = Duration(milliseconds: 120);
  static const enter = Duration(milliseconds: 180);
  static const sheet = Duration(milliseconds: 250);
  static const page = Duration(milliseconds: 320);
  static const curveIn = Curves.easeOutCubic;
  static const curveOut = Curves.easeInCubic;

  /// Delay between rows that come in one after the other (not a duration of
  /// the scale).
  static const stagger = Duration(milliseconds: 20);
  static const staggered = 12;
}

/// Waits and loops that are not movement: they keep their value whatever the
/// motion scale says.
abstract final class CcTiming {
  static const debounce = Duration(milliseconds: 250);
  static const radioDebounce = Duration(milliseconds: 400);
  static const afterRefresh = Duration(milliseconds: 400);
  static const poll = Duration(milliseconds: 500);
  static const avatarPulse = Duration(milliseconds: 1200);
}

Duration ccDuration(BuildContext context, Duration d) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

const _figtree = 'Figtree';
const _unbounded = 'Unbounded';

/// Both families are variable fonts: weight goes in `fontWeight` (so the
/// engine doesn't fake-bold) and in `fontVariations` (so the axis moves).
TextStyle ccStyle(
  String family,
  double size,
  int weight, {
  required Color color,
  double? height,
  bool tabular = false,
}) => TextStyle(
  fontFamily: family,
  fontSize: size,
  fontWeight: FontWeight.values[(weight ~/ 100) - 1],
  fontVariations: [FontVariation.weight(weight.toDouble())],
  color: color,
  height: height,
  fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
);

TextTheme buildTextTheme(CcColors c) => TextTheme(
  displaySmall: ccStyle(_unbounded, 30, 700, color: c.text, height: 1.1),
  headlineSmall: ccStyle(_unbounded, 24, 600, color: c.text),
  titleLarge: ccStyle(_figtree, 22, 700, color: c.text),
  titleMedium: ccStyle(_figtree, 18, 700, color: c.text),
  titleSmall: ccStyle(_figtree, 14, 700, color: c.text),
  bodyLarge: ccStyle(_figtree, 15, 600, color: c.text),
  bodyMedium: ccStyle(_figtree, 13, 400, color: c.textMuted),
  bodySmall: ccStyle(_figtree, 12, 400, color: c.textMuted),
  labelLarge: ccStyle(_figtree, 14, 700, color: c.text),
  labelMedium: ccStyle(_figtree, 12, 600, color: c.textMuted),
  labelSmall: ccStyle(_figtree, 12, 500, color: c.textMuted, tabular: true),
);
