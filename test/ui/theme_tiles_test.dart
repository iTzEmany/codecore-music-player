import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/providers/theme_providers.dart';
import 'package:codecore/ui/screens/settings/theme_editor_screen.dart';
import 'package:codecore/ui/screens/settings/theme_tiles.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
}

const _sea = CustomTheme(id: 'sea', name: 'Mare');

void main() {
  late Harness h;
  late ProviderContainer c;

  Future<void> open(WidgetTester tester, {void Function(ProviderContainer)? before}) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: SingleChildScrollView(child: ThemeTiles())));
    c = ProviderScope.containerOf(tester.element(find.byType(ThemeTiles)));
    if (before != null) {
      before(c);
      await _settle(tester);
    }
  }

  testWidgets('the three built-in themes, a «new theme» swatch, the accent row and the import row', (tester) async {
    await open(tester);
    for (final n in ['Notte viola', 'Nero puro', 'Chiaro', 'Nuovo tema']) {
      expect(find.text(n), findsOneWidget, reason: n);
    }
    expect(find.text('Importa tema'), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-edit')), findsNothing);
    expect(find.text("Colore d'accento"), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('«Nuovo tema» opens the editor on a copy of what is in use, with the accent chosen', (tester) async {
    await open(tester, before: (c) => c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: 'chiaro', accent: 'blu')));
    await tester.tap(find.byKey(const ValueKey('theme-new')));
    await _settle(tester);
    final editor = tester.widget<ThemeEditorScreen>(find.byType(ThemeEditorScreen));
    expect(editor.initial.base, AppThemeId.chiaro);
    expect(editor.initial.name, 'Tema personalizzato 1');
    expect(editor.initial.overrides[CcToken.accent], buildPalette(AppThemeId.chiaro, CcAccent.blu).accent);
    expect(c.read(customThemesProvider).items, isEmpty, reason: 'nothing is stored until it is saved');
    await h.dispose(tester);
  });

  testWidgets('a theme of the user is listed, can be picked, and then shows its actions', (tester) async {
    await open(tester, before: (c) => c.read(customThemesProvider.notifier).put(_sea));
    expect(find.byKey(const ValueKey('theme-sea')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-edit')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('theme-sea')));
    await _settle(tester);
    expect(c.read(settingsProvider).theme, 'custom:sea');
    for (final k in ['theme-edit', 'theme-duplicate', 'theme-export', 'theme-delete']) {
      expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
    }
    expect(find.text("Colore d'accento"), findsNothing, reason: 'the accent is part of the theme now');
    await h.dispose(tester);
  });

  testWidgets('«Modifica» opens the theme in the editor', (tester) async {
    await open(tester, before: (c) {
      c.read(customThemesProvider.notifier).put(_sea);
      c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: 'custom:sea'));
    });
    await tester.tap(find.byKey(const ValueKey('theme-edit')));
    await _settle(tester);
    expect(tester.widget<ThemeEditorScreen>(find.byType(ThemeEditorScreen)).initial, _sea);
    await h.dispose(tester);
  });

  testWidgets('«Duplica» adds a copy under a new id and picks it', (tester) async {
    await open(tester, before: (c) {
      c.read(customThemesProvider.notifier).put(_sea.withColor(CcToken.accent, const Color(0xFF00AA88)));
      c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: 'custom:sea'));
    });
    await tester.tap(find.byKey(const ValueKey('theme-duplicate')));
    await _settle(tester);
    final items = c.read(customThemesProvider).items;
    expect(items, hasLength(2));
    final copy = items.last;
    expect(copy.id, isNot('sea'));
    expect(copy.name, 'Mare (copia)');
    expect(copy.overrides, items.first.overrides);
    expect(c.read(settingsProvider).theme, 'custom:${copy.id}');
    await h.dispose(tester);
  });

  testWidgets('«Elimina» removes the theme in use, back to Notte, and «Annulla» brings it back', (tester) async {
    await open(tester, before: (c) {
      c.read(customThemesProvider.notifier).put(_sea);
      c.read(settingsProvider.notifier).update((s) => s.copyWith(theme: 'custom:sea'));
    });
    await tester.tap(find.byKey(const ValueKey('theme-delete')));
    await _settle(tester);
    expect(c.read(customThemesProvider).items, isEmpty);
    expect(c.read(settingsProvider).theme, 'notte');
    expect(find.text('Tema eliminato'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await _settle(tester);
    expect(c.read(customThemesProvider).byId('sea'), _sea);
    expect(c.read(settingsProvider).theme, 'custom:sea', reason: 'it was the one in use');
    await h.dispose(tester);
  });

  testWidgets('with twenty themes «Nuovo tema» says so instead of opening the editor', (tester) async {
    await open(tester, before: (c) {
      for (var i = 0; i < kMaxCustomThemes; i++) {
        c.read(customThemesProvider.notifier).put(CustomTheme(id: 't$i', name: 't$i'));
      }
    });
    await tester.tap(find.byKey(const ValueKey('theme-new')));
    await _settle(tester);
    expect(find.byType(ThemeEditorScreen), findsNothing);
    expect(find.text('Hai già 20 temi: eliminane uno'), findsOneWidget);
    await h.dispose(tester);
  });
}
