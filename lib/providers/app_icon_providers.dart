import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform.dart';
import '../services/app_icon/app_icon.dart';
import 'settings_providers.dart';
import 'theme_providers.dart';

final appIconChannelProvider = Provider<AppIconChannel>((ref) => MethodAppIconChannel());

/// Only Android has a launcher icon to change; tests override this.
final appIconSupportedProvider = Provider<bool>((ref) => isAndroid);

/// The icon variant that matches the theme and accent in use.
final appIconVariantProvider = Provider<String>((ref) {
  final (theme, accent) = ref.watch(settingsProvider.select((s) => (s.theme, s.accent)));
  return appIconVariantFor(theme, accent, ref.watch(customThemesProvider));
});
