import 'package:codecore/ui/widgets/prompt_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _Run {
  String? result;
  bool done = false;
}

Future<(Harness, _Run)> _open(
  WidgetTester tester, {
  String initial = '',
  int? maxLength,
}) async {
  final h = await Harness.create(tester);
  final run = _Run();
  await h.pump(
    tester,
    Builder(
      builder: (c) => Scaffold(
        body: TextButton(
          onPressed: () async {
            run.result = await promptName(
              c,
              title: 'Titolo',
              confirmLabel: 'Ok',
              hint: 'Suggerimento',
              initial: initial,
              maxLength: maxLength ?? 60,
            );
            run.done = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump(const Duration(milliseconds: 400));
  return (h, run);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 400));
}

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  testWidgets('shows title, labels, hint, initial text and the limit', (
    tester,
  ) async {
    final (h, _) = await _open(tester, initial: 'Old', maxLength: 40);
    expect(find.text('Titolo'), findsOneWidget);
    expect(find.text('Ok'), findsOneWidget);
    expect(find.text('Old'), findsOneWidget);
    expect(_field(tester).decoration?.hintText, 'Suggerimento');
    expect(_field(tester).maxLength, 40);
    await h.dispose(tester);
  });

  testWidgets('the button and the keyboard return the trimmed name', (
    tester,
  ) async {
    final (h, run) = await _open(tester);
    await _type(tester, '  Mix  ');
    await _tap(tester, 'Ok');
    expect(run.result, 'Mix');
    await h.dispose(tester);

    final (h2, run2) = await _open(tester);
    await _type(tester, ' Gym ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 400));
    expect(run2.result, 'Gym');
    await h2.dispose(tester);
  });

  testWidgets('a blank name keeps the dialog open, button and keyboard', (
    tester,
  ) async {
    final (h, run) = await _open(tester);
    await _type(tester, '   ');
    await _tap(tester, 'Ok');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(run.done, isFalse);
    expect(find.byType(AlertDialog), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('«Annulla» returns null', (tester) async {
    final (h, run) = await _open(tester);
    await _tap(tester, 'Annulla');
    expect(run.done, isTrue);
    expect(run.result, isNull);
    await h.dispose(tester);
  });
}
