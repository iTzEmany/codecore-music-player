import 'package:codecore/ui/screens/playlists/export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('export dialog offers the three formats; relative only for M3U8',
      (tester) async {
    final h = await Harness.create(tester);
    await h.pump(tester, const Scaffold(body: ExportDialog()));
    expect(find.text('Esporta playlist'), findsOneWidget);
    expect(find.textContaining('M3U8'), findsOneWidget);
    expect(find.textContaining('CSV'), findsOneWidget);
    expect(find.textContaining('JSON'), findsOneWidget);
    expect(find.text('Percorsi relativi'), findsOneWidget);
    await tester.tap(find.textContaining('CSV'));
    await tester.pump();
    expect(find.text('Percorsi relativi'), findsNothing);
    await h.dispose(tester);
  });
}
