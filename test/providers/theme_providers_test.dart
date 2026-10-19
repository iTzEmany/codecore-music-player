import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/theme_providers.dart';
import 'package:codecore/services/backup/backup_service.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(ProviderContainer, SharedPreferences)> make([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      settingsStoreProvider.overrideWithValue(SettingsStore(prefs)),
    ]);
    addTearDown(c.dispose);
    return (c, prefs);
  }

  const sea = CustomTheme(id: 'sea', name: 'Mare');
  final seaBlue = sea.withColor(CcToken.bg, const Color(0xFF062040));

  test('a saved theme is still there after a restart', () async {
    final (c, prefs) = await make();
    expect(c.read(customThemesProvider).items, isEmpty);
    expect(c.read(customThemesProvider.notifier).put(seaBlue), isTrue);
    await Future<void>.delayed(Duration.zero);

    final again = ProviderContainer(overrides: [
      settingsStoreProvider.overrideWithValue(SettingsStore(prefs)),
    ]);
    addTearDown(again.dispose);
    final t = again.read(customThemesProvider).byId('sea')!;
    expect(t.name, 'Mare');
    expect(t.overrides[CcToken.bg], const Color(0xFF062040));
  });

  test('a new theme over the limit is refused; changing one is not', () async {
    final (c, _) = await make();
    final n = c.read(customThemesProvider.notifier);
    for (var i = 0; i < kMaxCustomThemes; i++) {
      expect(n.put(CustomTheme(id: 't$i', name: 't$i')), isTrue);
    }
    expect(n.put(const CustomTheme(id: 'extra', name: 'x')), isFalse);
    expect(n.put(const CustomTheme(id: 't2', name: 'renamed')), isTrue);
    expect(c.read(customThemesProvider).byId('t2')!.name, 'renamed');
  });

  test('the colours in use follow the theme setting, its accent and the user themes', () async {
    final (c, _) = await make();
    expect(c.read(themeColorsProvider).bg, CcColors.notte.bg);

    c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: 'chiaro', accent: 'blu'));
    expect(c.read(themeColorsProvider).isLight, isTrue);
    expect(c.read(themeColorsProvider).accent, buildPalette(AppThemeId.chiaro, CcAccent.blu).accent);

    c.read(customThemesProvider.notifier).put(seaBlue);
    c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: customThemeSettingValue('sea')));
    expect(c.read(themeColorsProvider).bg, const Color(0xFF062040));
  });

  test('a theme that no longer exists is Notte, not an error', () async {
    final (c, _) = await make({'theme': 'custom:ghost'});
    expect(c.read(themeColorsProvider).bg, CcColors.notte.bg);
  });

  test('deleting the theme in use goes back to Notte; deleting another leaves the setting', () async {
    final (c, _) = await make();
    final n = c.read(customThemesProvider.notifier);
    n.put(seaBlue);
    n.put(const CustomTheme(id: 'other', name: 'Other'));
    c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: customThemeSettingValue('sea')));

    n.remove('other');
    expect(c.read(settingsProvider).theme, 'custom:sea');
    n.remove('sea');
    expect(c.read(settingsProvider).theme, 'notte');
    expect(c.read(customThemesProvider).items, isEmpty);
  });

  test('the themes travel in the backup with the other settings', () async {
    final (c, prefs) = await make();
    c.read(customThemesProvider.notifier).put(seaBlue);
    await Future<void>.delayed(Duration.zero);
    final json = settingsToJson(prefs);
    expect(json.containsKey('customThemes'), isTrue);

    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    await applySettingsJson(fresh, json);
    expect(CustomThemes.decode(fresh.getString('customThemes')).byId('sea')!.name, 'Mare');
  });
}
