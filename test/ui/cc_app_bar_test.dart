import 'package:codecore/ui/widgets/cc_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds a themed AppBar with title and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          appBarTheme: const AppBarTheme(titleTextStyle: TextStyle(fontSize: 31)),
        ),
        home: Scaffold(
          appBar: CcAppBar(
            title: 'Titolo',
            actions: const [Icon(Icons.add)],
          ),
        ),
      ),
    );
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Titolo'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    // Typography comes from the theme, not from the widget.
    final style = tester.widget<DefaultTextStyle>(
      find.ancestor(of: find.text('Titolo'), matching: find.byType(DefaultTextStyle)).first,
    ).style;
    expect(style.fontSize, 31);
  });

  testWidgets('preferredSize includes the bottom (TabBar)', (tester) async {
    const bottom = PreferredSize(preferredSize: Size.fromHeight(48), child: SizedBox());
    expect(const CcAppBar().preferredSize.height, kToolbarHeight);
    expect(const CcAppBar(bottom: bottom).preferredSize.height, kToolbarHeight + 48);
  });

  testWidgets('titleWidget wins over title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: CcAppBar(title: 'a', titleWidget: Text('b'))),
      ),
    );
    expect(find.text('b'), findsOneWidget);
    expect(find.text('a'), findsNothing);
  });
}
