import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/ui/widgets/color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = CcColorPickerLabels(
  hue: 'Hue',
  saturationValue: 'Saturation and value',
  alpha: 'Alpha',
  hex: 'Hex code',
  invalidHex: 'Invalid code',
  recent: 'Recent',
);

Widget _host(Widget child, {double width = 400}) => MaterialApp(
  theme: ThemeData(extensions: const [CcColors.notte]),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

/// Keeps the colour in a parent, like real callers do.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.initial,
    required this.log,
    this.allowAlpha = false,
    this.recent = const [],
  });
  final Color initial;
  final List<Color> log;
  final bool allowAlpha;
  final List<Color> recent;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Color c = widget.initial;

  @override
  Widget build(BuildContext context) => CcColorPicker(
    color: c,
    labels: _labels,
    allowAlpha: widget.allowAlpha,
    recent: widget.recent,
    onChanged: (v) {
      widget.log.add(v);
      setState(() => c = v);
    },
  );
}

Finder get _square => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter != null && w.size.height > 100,
);

HSVColor _hsv(Color c) => HSVColor.fromColor(c);

void main() {
  group('helpers', () {
    test('parseHexColor accepts 3/6/8 digits, with or without #', () {
      expect(parseHexColor('#abc'), const Color(0xFFAABBCC));
      expect(parseHexColor('abc'), const Color(0xFFAABBCC));
      expect(parseHexColor('#A06BFF'), const Color(0xFFA06BFF));
      expect(parseHexColor('a06bff'), const Color(0xFFA06BFF));
      expect(parseHexColor('#80A06BFF'), const Color(0x80A06BFF));
      expect(parseHexColor('  #a06bff  '), const Color(0xFFA06BFF));
    });

    test('parseHexColor rejects invalid input', () {
      for (final s in [
        '',
        '#',
        '#ab',
        '#abcd',
        '#abcde',
        'ggg',
        '#12345678 9',
      ]) {
        expect(parseHexColor(s), isNull, reason: s);
      }
    });

    test('colorToHex formats and round-trips', () {
      expect(colorToHex(const Color(0xFFA06BFF)), '#A06BFF');
      expect(colorToHex(const Color(0x80A06BFF), withAlpha: true), '#80A06BFF');
      expect(colorToHex(const Color(0x80A06BFF)), '#A06BFF');
      for (final c in [const Color(0xFF010203), const Color(0x7F00FF10)]) {
        expect(parseHexColor(colorToHex(c, withAlpha: true)), c);
      }
    });
  });

  group('widget', () {
    testWidgets('typing a valid hex calls onChanged', (tester) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(_Harness(initial: const Color(0xFF112233), log: log)),
      );
      await tester.enterText(find.byType(TextField), '#FF0000');
      expect(log.last, const Color(0xFFFF0000));
      expect(find.text('Invalid code'), findsNothing);
    });

    testWidgets('typing an invalid hex shows the error only', (tester) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(_Harness(initial: const Color(0xFF112233), log: log)),
      );
      await tester.enterText(find.byType(TextField), '#12');
      await tester.pump();
      expect(find.text('Invalid code'), findsOneWidget);
      expect(log, isEmpty);
    });

    testWidgets('dragging in the square changes saturation and value', (
      tester,
    ) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(_Harness(initial: const Color(0xFFFF0000), log: log)),
      );
      final r = tester.getRect(_square);
      await tester.dragFrom(
        r.topRight - const Offset(1, -1),
        Offset(-r.width / 2, r.height / 2),
      );
      await tester.pump();
      expect(log, isNotEmpty);
      final h = _hsv(log.last);
      expect(h.saturation, closeTo(0.5, 0.1));
      expect(h.value, closeTo(0.5, 0.1));
    });

    testWidgets('hue slider keeps saturation and value', (tester) async {
      final log = <Color>[];
      final start = HSVColor.fromAHSV(1, 200, 0.6, 0.8).toColor();
      await tester.pumpWidget(_host(_Harness(initial: start, log: log)));
      await tester.drag(
        find.byKey(const ValueKey('hue-slider')),
        const Offset(60, 0),
      );
      await tester.pump();
      expect(log, isNotEmpty);
      final h = _hsv(log.last);
      expect((h.hue - 200).abs(), greaterThan(5));
      expect(h.saturation, closeTo(0.6, 0.03));
      expect(h.value, closeTo(0.8, 0.03));
    });

    testWidgets('hue track is a rainbow gradient and tapping jumps', (
      tester,
    ) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(_Harness(initial: const Color(0xFFFF0000), log: log)),
      );
      final track = find.descendant(
        of: find.byKey(const ValueKey('hue-slider')),
        matching: find.byKey(const ValueKey('track-gradient')),
      );
      final box = tester.widget<DecoratedBox>(track);
      final g = (box.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(g.colors.length, 7);
      expect(g.colors.toSet().length, 6); // red repeats at both ends
      final r = tester.getRect(find.byKey(const ValueKey('hue-slider')));
      await tester.tapAt(Offset(r.left + r.width * 0.5, r.center.dy));
      await tester.pump();
      expect(_hsv(log.last).hue, closeTo(180, 15));
    });

    testWidgets('no overflow at 360 px with 150% text', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: _host(
            _Harness(
              initial: const Color(0xFFFF0000),
              log: [],
              allowAlpha: true,
            ),
            width: 360,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a grey keeps its hue', (tester) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(_Harness(initial: const Color(0xFF00FF00), log: log)),
      );
      final r = tester.getRect(_square);
      await tester.tapAt(r.centerLeft);
      await tester.pump();
      expect(_hsv(log.last).saturation, closeTo(0, 0.01));
      await tester.tapAt(r.topRight + const Offset(-1, 1));
      await tester.pump();
      final h = _hsv(log.last);
      expect(h.hue, closeTo(120, 3));
    });

    testWidgets('without alpha the colour is always opaque', (tester) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(_Harness(initial: const Color(0x40FF0000), log: log)),
      );
      expect(find.byKey(const ValueKey('alpha-slider')), findsNothing);
      await tester.tapAt(tester.getCenter(_square));
      await tester.enterText(find.byType(TextField), '#80112233');
      expect(log, isNotEmpty);
      for (final c in log) {
        expect(c.toARGB32() >> 24, 0xFF);
      }
    });

    testWidgets('with alpha a second slider changes the alpha', (tester) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(
          _Harness(
            initial: const Color(0xFFFF0000),
            log: log,
            allowAlpha: true,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('alpha-slider')), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('alpha-slider')),
        const Offset(-60, 0),
      );
      await tester.pump();
      expect(log.last.toARGB32() >> 24, lessThan(0xFF));
    });

    testWidgets('tapping a recent swatch selects it', (tester) async {
      final log = <Color>[];
      const recent = [Color(0xFF123456), Color(0xFFABCDEF)];
      await tester.pumpWidget(
        _host(
          _Harness(initial: const Color(0xFFFF0000), log: log, recent: recent),
        ),
      );
      await tester.tap(find.byKey(ValueKey('recent-${recent[1].toARGB32()}')));
      expect(log.last.toARGB32(), recent[1].toARGB32());
    });

    for (final w in [280.0, 600.0]) {
      testWidgets('no overflow at width $w', (tester) async {
        await tester.pumpWidget(
          _host(
            _Harness(
              initial: const Color(0xFFFF0000),
              log: [],
              allowAlpha: true,
              recent: List.generate(12, (i) => Color(0xFF000000 + i * 99999)),
            ),
            width: w,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(tester.getRect(_square).height, lessThanOrEqualTo(220));
      });
    }

    testWidgets('arrow keys move the thumb', (tester) async {
      final log = <Color>[];
      await tester.pumpWidget(
        _host(
          _Harness(
            initial: HSVColor.fromAHSV(1, 0, 0.5, 0.5).toColor(),
            log: log,
          ),
        ),
      );
      await tester.tapAt(tester.getCenter(_square));
      await tester.pump();
      log.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(log, isNotEmpty);
      final before = _hsv(log.last);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      final after = _hsv(log.last);
      expect(after.value, greaterThan(before.value));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_hsv(log.last).saturation - after.saturation, closeTo(0.1, 0.02));
    });
  });
}
