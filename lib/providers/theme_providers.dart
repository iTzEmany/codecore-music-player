import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../core/uuid.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/tokens.dart' show CcColors;
import 'settings_providers.dart';

/// The themes the user made, saved on every change.
class CustomThemesNotifier extends Notifier<CustomThemes> {
  @override
  CustomThemes build() =>
      CustomThemes.decode(ref.read(settingsStoreProvider).readCustomThemesRaw());

  void _set(CustomThemes next) {
    state = next;
    ref.read(settingsStoreProvider).writeCustomThemesRaw(next.encode()).catchError(
      (Object e, StackTrace st) {
        AppLog.w('could not save the themes', e, st);
      },
    );
  }

  /// A new theme id (not used by any of the existing ones).
  String newId() {
    var id = newUuid();
    while (state.byId(id) != null) {
      id = newUuid();
    }
    return id;
  }

  /// Saves [theme] (a new one, or a changed one with the same id). False when
  /// it is new and the list is full.
  bool put(CustomTheme theme) {
    final next = state.put(theme);
    if (identical(next, state)) return false;
    _set(next);
    return true;
  }

  /// Deletes a theme; if it was the one in use the app goes back to Notte.
  void remove(String id) {
    _set(state.remove(id));
    final current = ref.read(settingsProvider).theme;
    if (customThemeIdOf(current) == id) {
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(theme: AppThemeId.notte.name));
    }
  }
}

final customThemesProvider =
    NotifierProvider<CustomThemesNotifier, CustomThemes>(CustomThemesNotifier.new);

/// The colours in use: the theme setting, its accent and the user's themes.
final themeColorsProvider = Provider<CcColors>((ref) {
  final s = ref.watch(settingsProvider);
  return resolveColors(s.theme, s.accent, ref.watch(customThemesProvider));
});

/// The background of the theme in use (plain when it is not one of the user's).
final themeBackgroundProvider = Provider<ThemeBackground>((ref) {
  final id = customThemeIdOf(ref.watch(settingsProvider).theme);
  if (id == null) return const ThemeBackground();
  return ref.watch(customThemesProvider).byId(id)?.background ?? const ThemeBackground();
});
