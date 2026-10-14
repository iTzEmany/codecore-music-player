import 'package:codecore/app.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  for (final scale in [0.9, 1.15]) {
    testWidgets('app builds without errors at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester, tracks: 3);
      await tester.pumpWidget(ProviderScope(
          overrides: h.overrides, child: const CodecoreApp()));
      await tester.pump(const Duration(milliseconds: 200));
      final container =
          ProviderScope.containerOf(tester.element(find.byType(CodecoreApp)));
      container
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(fontScale: scale));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.text('Song 0'), findsOneWidget);
      await h.dispose(tester);
    });
  }
}
