import 'package:codecore/ui/screens/settings/log_export_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('log export tile explains it is disabled in debug builds',
      (tester) async {
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: LogExportTile()));
    expect(find.text('Esporta log'), findsOneWidget);
    expect(find.textContaining('versione installata'), findsOneWidget);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.enabled, isFalse);
    await h.dispose(tester);
  });
}
