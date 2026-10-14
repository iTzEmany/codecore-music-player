import 'package:flutter/material.dart';

enum AppThemeId { oled, carbon, navy, light }

AppThemeId appThemeIdFromName(String name) => AppThemeId.values
    .firstWhere((e) => e.name == name, orElse: () => AppThemeId.oled);

const _seed = Color(0xFF6C5CE7);

/// Text size is applied app-wide through MediaQuery's text scaler (see app.dart):
/// scaling the TextTheme directly asserts on styles without a font size.
ThemeData buildTheme(AppThemeId id, bool compact) {
  final dark = id != AppThemeId.light;
  var scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  Color? background;
  Color? card;
  switch (id) {
    case AppThemeId.oled:
      background = const Color(0xFF000000);
      card = const Color(0xFF0A0A0A);
    case AppThemeId.carbon:
      background = const Color(0xFF121212);
      card = const Color(0xFF1E1E1E);
    case AppThemeId.navy:
      background = const Color(0xFF10131A);
      card = const Color(0xFF151822);
    case AppThemeId.light:
      break;
  }
  if (background != null) {
    scheme = scheme.copyWith(
      surface: background,
      surfaceContainerLowest: background,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: card,
      surfaceContainerHighest: Color.alphaBlend(
          const Color(0x14FFFFFF), card ?? background),
    );
  }
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
    // Keeps "Impostazioni"/"Einstellungen" on one line in the 5-item bar.
    navigationBarTheme: const NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
    ),
  );
}

/// Row height for track lists (fixed so lists can use `itemExtent`).
double trackRowExtent(bool compact) => compact ? 48 : 64;

/// Same, grown with the user's text size so two-line rows never overflow.
double trackRowExtentOf(BuildContext context, bool compact) {
  final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
  return trackRowExtent(compact) * (scale > 1 ? scale : 1);
}
