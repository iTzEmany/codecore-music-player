import 'package:codecore/ui/widgets/alpha_scroller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leadingLetter folds accents and groups the rest under #', () {
    expect(leadingLetter('Àlbum'), 'A');
    expect(leadingLetter('élan'), 'E');
    expect(leadingLetter('  zebra'), 'Z');
    expect(leadingLetter('7 Years'), '#');
    expect(leadingLetter('¿Qué?'), '#');
    expect(leadingLetter(null), '#');
    expect(leadingLetter(''), '#');
  });

  testWidgets('dragging the strip jumps the list', (tester) async {
    final c = ScrollController();
    final letters = [for (var i = 0; i < 100; i++) String.fromCharCode(65 + i % 26)];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AlphaScroller(
          controller: c,
          itemExtent: 50,
          letters: letters,
          child: ListView.builder(
            controller: c,
            itemExtent: 50,
            itemCount: 100,
            itemBuilder: (_, i) => Text('row $i'),
          ),
        ),
      ),
    ));
    expect(c.offset, 0);
    final size = tester.getSize(find.byType(Scaffold));
    // Drag from the top to the middle of the strip at the right edge.
    await tester.dragFrom(Offset(size.width - 10, 10), Offset(0, size.height / 2));
    await tester.pump();
    expect(c.offset, greaterThan(1000));
  });
}
