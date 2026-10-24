import 'package:codecore/ui/theme/tokens.dart';
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

  testWidgets('ccDuration is zero with reduced motion (description AnimatedSize)', (tester) async {
    late Duration reduced, normal;
    Widget app(bool off) => MediaQuery(
      data: MediaQueryData(disableAnimations: off),
      child: Builder(builder: (context) {
        final d = ccDuration(context, const Duration(milliseconds: 200));
        off ? reduced = d : normal = d;
        return const SizedBox();
      }),
    );
    await tester.pumpWidget(app(true));
    await tester.pumpWidget(app(false));
    expect(reduced, Duration.zero);
    expect(normal, const Duration(milliseconds: 200));
  });
}
