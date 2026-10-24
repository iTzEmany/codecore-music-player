import 'package:codecore/ui/widgets/progress_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFrame(WidgetTester t, double? progress) => t.pumpWidget(
    MaterialApp(
      home: Center(child: ProgressFrame(size: 52, progress: progress)),
    ),
  );

  testWidgets('frame: half progress paints less than the full frame', (t) async {
    // Paint calls are recorded through a matcher on the painter's output.
    await pumpFrame(t, 0.5);
    final half = find.byType(ProgressFrame);
    expect(half, findsOneWidget);
    expect(
      find.descendant(of: half, matching: find.byType(CustomPaint)),
      paints
        ..path(strokeWidth: 2) // track
        ..path(strokeWidth: 2), // arc
    );
    await pumpFrame(t, null);
    expect(
      find.descendant(
        of: find.byType(ProgressFrame),
        matching: find.byType(CustomPaint),
      ),
      paints..path(strokeWidth: 2),
    );
  });
}
