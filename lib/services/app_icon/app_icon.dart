import 'package:flutter/services.dart';

import '../../core/app_log.dart';
import '../../ui/theme/custom_theme.dart';
import '../../ui/theme/palette.dart';

/// The launcher icon on Android: one of 16 variants, `<accent>_<dark|light>`
/// (`viola_dark` is the default). Desktop has no such thing.
abstract class AppIconChannel {
  /// The variant enabled right now; null when it cannot be known.
  Future<String?> current();

  /// Asks for [variant]; the switch itself happens when the app is left.
  Future<void> setIcon(String variant);
}

const defaultAppIcon = 'viola_dark';

class MethodAppIconChannel implements AppIconChannel {
  static const _channel = MethodChannel('codecore/icon');

  @override
  Future<String?> current() async {
    try {
      return await _channel.invokeMethod<String>('current');
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e, st) {
      AppLog.w('could not read the app icon', e, st);
      return null;
    }
  }

  @override
  Future<void> setIcon(String variant) async {
    try {
      await _channel.invokeMethod<void>('setIcon', {'variant': variant});
    } on MissingPluginException catch (e, st) {
      AppLog.w('app icon channel missing', e, st);
    } on PlatformException catch (e, st) {
      AppLog.w('could not set the app icon', e, st);
    }
  }
}

/// The icon variant matching the look in use: a built-in theme gives its
/// ground (only Chiaro is light) and the accent chosen; a theme of the user's
/// gives the accent nearest to its own and the ground of its background.
String appIconVariantFor(String theme, String accent, CustomThemes customs) {
  final customId = customThemeIdOf(theme);
  final custom = customId == null ? null : customs.byId(customId);
  if (custom == null) {
    final id = appThemeIdFromName(theme);
    return '${accentFromName(accent).name}_${id == AppThemeId.chiaro ? 'light' : 'dark'}';
  }
  final c = custom.resolve();
  CcAccent? best;
  var bestDist = double.infinity;
  for (final a in CcAccent.values) {
    for (final t in [AppThemeId.notte, AppThemeId.chiaro]) {
      final d = _rgbDistance(buildPalette(t, a).accent, c.accent);
      if (d < bestDist) {
        bestDist = d;
        best = a;
      }
    }
  }
  return '${best!.name}_${c.bg.computeLuminance() < 0.5 ? 'dark' : 'light'}';
}

double _rgbDistance(Color a, Color b) {
  final dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b;
  return dr * dr + dg * dg + db * db;
}
