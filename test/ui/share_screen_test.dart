import 'package:codecore/ui/screens/share/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('share screen: send and receive tabs', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const ShareScreen());
    expect(find.text('Dispositivi vicini'), findsOneWidget);
    expect(find.text('Tutta la libreria'), findsOneWidget);
    // Opened without tracks the selection starts empty, not «whole library».
    expect(find.text('Selezione (0 brani)'), findsOneWidget);
    expect(find.text('Scegli brani'), findsOneWidget);
    await tester.tap(find.text('Collegamento manuale (IP e PIN)'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Avvia condivisione'), findsOneWidget);
    await tester.tap(find.text('Ricevi'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Connetti'), findsOneWidget);
    expect(find.text('PIN'), findsWidgets);
    await h.dispose(tester);
  });
}
