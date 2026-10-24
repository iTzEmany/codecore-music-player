import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/ui/widgets/show_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _pump(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Builder(builder: (c) { ctx = c; return const SizedBox(); })),
    ),
  );
  return ctx;
}

void main() {
  testWidgets('plain message lasts CcTiming.msg, then goes away', (tester) async {
    final ctx = await _pump(tester);
    showMsg(ctx, 'ciao');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ciao'), findsOneWidget);
    await tester.pump(CcTiming.msg);
    await tester.pumpAndSettle();
    expect(find.text('ciao'), findsNothing);
  });

  testWidgets('with an action it times out after CcTiming.msgAction', (tester) async {
    final ctx = await _pump(tester);
    showMsg(ctx, 'fatto', action: SnackBarAction(label: 'Annulla', onPressed: () {}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Annulla'), findsOneWidget);
    await tester.pump(CcTiming.msgAction);
    await tester.pumpAndSettle();
    expect(find.text('fatto'), findsNothing);
  });

  testWidgets('a new message replaces the old one (one at a time)', (tester) async {
    final ctx = await _pump(tester);
    showMsg(ctx, 'uno');
    showMsg(ctx, 'due');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('uno'), findsNothing);
    expect(find.text('due'), findsOneWidget);
  });

  testWidgets('a context unmounted during an await does not throw', (tester) async {
    final ctx = await _pump(tester);
    await tester.pumpWidget(const SizedBox());
    showMsg(ctx, 'tardi');
    expect(tester.takeException(), isNull);
  });
}
