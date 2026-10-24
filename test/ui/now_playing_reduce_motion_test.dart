import 'package:codecore/ui/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spin_support.dart';

void main() {
  testWidgets('option off (default): the cover does not turn', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: spinOverrides(spinCover: false),
      child: const MaterialApp(
        home: Scaffold(body: SpinWhilePlaying(trackKey: 'a', child: SizedBox(width: 10, height: 10))),
      ),
    ));
    await tester.pump(const Duration(seconds: 5));
    expect(find.descendant(of: find.byType(SpinWhilePlaying), matching: find.byType(RotationTransition)), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
