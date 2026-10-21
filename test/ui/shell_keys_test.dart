import 'package:codecore/ui/shell/shell_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _space = SingleActivator(LogicalKeyboardKey.space);
const _next = SingleActivator(LogicalKeyboardKey.arrowRight, control: true);

Widget _app({
  required List<String> log,
  required TextEditingController text,
  required bool Function() showField,
}) => MaterialApp(
  home: ShellKeys(
    bindings: {_space: () => log.add('space'), _next: () => log.add('next')},
    textOnly: const {_space},
    child: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            Offstage(
              offstage: !showField(),
              child: ExcludeFocus(
                excluding: !showField(),
                child: TextField(controller: text),
              ),
            ),
            const Text('page'),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a text field gets Space as text, not as a shortcut', (
    tester,
  ) async {
    final log = <String>[];
    final text = TextEditingController();
    addTearDown(text.dispose);
    await tester.pumpWidget(_app(log: log, text: text, showField: () => true));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'long');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(log, isEmpty);
    // Other shortcuts still work with the field focused.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(log, ['next']);
  });

  testWidgets('shortcuts come back after the focused widget goes offstage', (
    tester,
  ) async {
    final log = <String>[];
    final text = TextEditingController();
    addTearDown(text.dispose);
    var show = true;
    late StateSetter set;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return _app(log: log, text: text, showField: () => show);
          },
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    set(() => show = false);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(log, ['space']);
  });
}
