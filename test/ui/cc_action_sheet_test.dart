import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/ui/widgets/cc_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/menu_support.dart';

String? _result = 'none';

Future<void> _open(WidgetTester tester, {String? title, bool wide = false}) async {
  tester.view.physicalSize = wide ? const Size(1600, 900) : const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _result = 'none';
  await tester.pumpWidget(
    MaterialApp(
      theme: buildThemeFromColors(CcColors.notte, false),
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () async => _result = await showCcActionSheet<String>(
            context: c,
            title: title,
            subtitle: title == null ? null : 'Sub',
            groups: [
              [
                const CcAction(icon: Icons.delete, label: 'Elimina', value: 'del', destructive: true),
                const CcAction(icon: Icons.add, label: 'Aggiungi', value: 'add'),
              ],
              [const CcAction(icon: Icons.sort, label: 'Ordina', value: 'sort', selected: true)],
            ],
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('header, rows of 59 dp, destructive last and red', (tester) async {
    await _open(tester, title: 'Brano');
    expect(find.text('Brano'), findsOneWidget);
    expect(find.text('Sub'), findsOneWidget);
    expect(shownMenuEntries(tester), ['add', 'sort', 'del']);
    expect(tester.getSize(find.ancestor(of: find.text('Aggiungi'), matching: find.byType(SizedBox)).first).height, 59);
    final red = tester.widget<Text>(find.text('Elimina')).style!.color;
    expect(red, CcColors.notte.error);
  });

  testWidgets('first row has the focus; Esc closes without a value', (tester) async {
    await _open(tester);
    expect(Focus.of(tester.element(find.text('Aggiungi'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi'), findsNothing);
    expect(_result, isNull);
  });

  testWidgets('barrierLabel is localized', (tester) async {
    await _open(tester);
    final route = ModalRoute.of(tester.element(find.text('Aggiungi')))! as PopupRoute;
    expect(route.barrierLabel, 'Chiudi');
  });

  testWidgets('at most 560 dp wide on desktop', (tester) async {
    await _open(tester, wide: true);
    expect(tester.getSize(find.byType(ListTile).first).width, lessThanOrEqualTo(560));
  });

  testWidgets('tapping a row returns its value', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Ordina'));
    await tester.pumpAndSettle();
    expect(_result, 'sort');
  });
}
