import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/app_icon_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/services/app_icon/app_icon.dart';
import 'package:codecore/ui/widgets/app_icon_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIcon implements AppIconChannel {
  _FakeIcon(this.shown);
  String shown;
  final asked = <String>[];

  @override
  Future<String?> current() async => shown;

  @override
  Future<void> setIcon(String variant) async => asked.add(variant);
}

Future<(ProviderContainer, _FakeIcon)> _pump(
  WidgetTester tester, {
  IconFollow follow = IconFollow.ask,
  String shown = 'viola_dark',
}) async {
  SharedPreferences.setMockInitialValues({'iconFollow': follow.name});
  final store = await SettingsStore.open();
  final icon = _FakeIcon(shown);
  final container = ProviderContainer(overrides: [
    settingsStoreProvider.overrideWithValue(store),
    appIconSupportedProvider.overrideWithValue(true),
    appIconChannelProvider.overrideWithValue(icon),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('it'),
      home: AppIconSync(child: Scaffold()),
    ),
  ));
  return (container, icon);
}

void _accent(ProviderContainer c, String accent, {String theme = 'notte'}) =>
    c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: theme, accent: accent));

// Lets the settings save timer (400 ms) fire so no timer is left pending.
Future<void> _settle(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 500));
  await t.pumpAndSettle();
}

void main() {
  const title = "Cambiare anche l'icona dell'app?";

  testWidgets('asks when the new look has another icon; changing applies it', (tester) async {
    final (c, icon) = await _pump(tester);
    _accent(c, 'rosso');
    await _settle(tester);
    expect(find.text(title), findsOneWidget);
    await tester.tap(find.text("Cambia l'icona"));
    await _settle(tester);
    expect(icon.asked, ['rosso_dark']);
    expect(c.read(settingsProvider).iconFollow, IconFollow.ask);
  });

  testWidgets('does not ask when the icon in use is already the right one', (tester) async {
    final (c, icon) = await _pump(tester, shown: 'rosso_dark');
    _accent(c, 'rosso');
    await _settle(tester);
    expect(find.text(title), findsNothing);
    expect(icon.asked, ['rosso_dark']);
  });

  testWidgets('"Non chiederlo più" + change: next time it switches without asking', (tester) async {
    final (c, icon) = await _pump(tester);
    _accent(c, 'blu');
    await _settle(tester);
    await tester.tap(find.text('Non chiederlo più'));
    await tester.tap(find.text("Cambia l'icona"));
    await _settle(tester);
    expect(c.read(settingsProvider).iconFollow, IconFollow.on);
    _accent(c, 'verde');
    await _settle(tester);
    expect(find.text(title), findsNothing);
    expect(icon.asked, ['blu_dark', 'verde_dark']);
  });

  testWidgets('"Non chiederlo più" + leave: never asks and never changes the icon', (tester) async {
    final (c, icon) = await _pump(tester);
    _accent(c, 'blu');
    await _settle(tester);
    await tester.tap(find.text('Non chiederlo più'));
    await tester.tap(find.text("Lascia com'è"));
    await _settle(tester);
    expect(c.read(settingsProvider).iconFollow, IconFollow.off);
    expect(icon.asked, ['viola_dark']);
    _accent(c, 'verde');
    await _settle(tester);
    expect(find.text(title), findsNothing);
    expect(icon.asked, ['viola_dark']);
  });
}
