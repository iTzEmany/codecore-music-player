import 'package:codecore/providers/selection_providers.dart';
import 'package:codecore/ui/screens/online/online_selection_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

const _key = 'online-scope-test';

void main() {
  testWidgets('the bar appears with a pick, selects all and closes; the actions get the picks', (tester) async {
    final h = await Harness.create(tester);
    var seen = <int>[];
    await h.pump(
      tester,
      OnlineSelectionScope(
        selectionKey: _key,
        ids: const [0, 1, 2],
        actions: (picked) {
          seen = picked.orderedIds;
          return const [];
        },
        child: Consumer(
          builder: (_, ref, _) => TextButton(
            onPressed: () => ref.read(selectionProvider(_key).notifier).toggle(1),
            child: const Text('pick'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pump();
    expect(seen, [1]);
    expect(find.byTooltip('Seleziona tutto'), findsOneWidget);
    await tester.tap(find.byTooltip('Seleziona tutto'));
    await tester.pump();
    expect(seen, [0, 1, 2]);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.byTooltip('Seleziona tutto'), findsNothing);
    await h.dispose(tester);
  });
}
