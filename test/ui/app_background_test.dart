import 'dart:io';
import 'dart:ui' as ui;

import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: ThemeData(extensions: const [CcColors.notte]),
      home: Scaffold(body: SizedBox(width: 200, height: 400, child: child)),
    );

void main() {
  const colors = CcColors.notte;
  const marker = Key('child');

  test('the gradient runs in the direction of the angle, from the background colour', () {
    ThemeBackground g(double angle) => ThemeBackground(
          kind: ThemeBackgroundKind.gradient,
          gradientEnd: const Color(0xFF112233),
          angle: angle,
        );
    final down = themeGradient(colors, g(180))!;
    final from = down.begin as Alignment, to = down.end as Alignment;
    expect([from.x, from.y, to.x, to.y], [closeTo(0, 1e-9), closeTo(-1, 1e-9), closeTo(0, 1e-9), closeTo(1, 1e-9)]);
    expect(down.colors, [colors.bg, const Color(0xFF112233)]);

    final right = themeGradient(colors, g(90))!.end as Alignment;
    expect(right.x, closeTo(1, 1e-9));
    expect(right.y, closeTo(0, 1e-9));
    final up = themeGradient(colors, g(0))!.end as Alignment;
    expect(up.y, closeTo(-1, 1e-9));
  });

  test('no gradient for a plain colour, a picture, or a gradient without an end colour', () {
    expect(themeGradient(colors, const ThemeBackground()), isNull);
    expect(themeGradient(colors, const ThemeBackground(kind: ThemeBackgroundKind.image, imagePath: '/x.png')), isNull);
    expect(themeGradient(colors, const ThemeBackground(kind: ThemeBackgroundKind.gradient)), isNull);
  });

  test('isCustom: only a background that needs more than the colour', () {
    expect(const ThemeBackground().isCustom, isFalse);
    expect(const ThemeBackground(kind: ThemeBackgroundKind.gradient).isCustom, isFalse);
    expect(const ThemeBackground(kind: ThemeBackgroundKind.gradient, gradientEnd: Color(0xFF000000)).isCustom, isTrue);
    expect(const ThemeBackground(kind: ThemeBackgroundKind.image).isCustom, isFalse);
    expect(const ThemeBackground(kind: ThemeBackgroundKind.image, imagePath: '/x.png').isCustom, isTrue);
  });

  testWidgets('a plain background adds nothing around the app', (tester) async {
    await tester.pumpWidget(_host(const AppBackground(
      colors: colors,
      background: ThemeBackground(),
      child: SizedBox(key: marker),
    )));
    expect(find.byKey(marker), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBackground), matching: find.byType(DecoratedBox)), findsNothing);
  });

  testWidgets('a gradient is painted behind the child', (tester) async {
    await tester.pumpWidget(_host(const AppBackground(
      colors: colors,
      background: ThemeBackground(kind: ThemeBackgroundKind.gradient, gradientEnd: Color(0xFF224466)),
      child: SizedBox(key: marker),
    )));
    final boxes = tester
        .widgetList<DecoratedBox>(find.descendant(of: find.byType(AppBackground), matching: find.byType(DecoratedBox)))
        .where((b) => (b.decoration as BoxDecoration).gradient != null);
    expect(boxes, hasLength(1));
    expect(find.byKey(marker), findsOneWidget);
  });

  testWidgets('a picture that is gone leaves the plain colour and no error', (tester) async {
    await tester.pumpWidget(_host(const AppBackground(
      colors: colors,
      background: ThemeBackground(kind: ThemeBackgroundKind.image, imagePath: '/no/such/picture.png', dim: 0.5, blur: 6),
      child: SizedBox(key: marker),
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.byKey(marker), findsOneWidget);
  });

  testWidgets('a real picture is shown, dimmed and blurred', (tester) async {
    final dir = Directory.systemTemp.createTempSync('bgw');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/p.png');
    await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      ui.Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 20, 20), ui.Paint()..color = const Color(0xFFAA0000));
      final img = await rec.endRecording().toImage(20, 20);
      file.writeAsBytesSync((await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
    });
    final asked = <(String, double)>[];
    Widget app(double blur) => _host(AppBackground(
          colors: colors,
          background: ThemeBackground(kind: ThemeBackgroundKind.image, imagePath: file.path, dim: 0.4, blur: blur),
          blurrer: (path, b) async {
            asked.add((path, b));
            return '${dir.path}/blurred-${b.round()}.png';
          },
          child: const SizedBox(key: marker),
        ));
    await tester.pumpWidget(app(3));
    await tester.pump(const Duration(milliseconds: 100));
    Image shown() => tester.widget<Image>(find.byType(Image));
    expect((shown().image as FileImage).file.path, endsWith('blurred-3.png'), reason: 'the blurred copy');
    expect(find.byType(ImageFiltered), findsNothing, reason: 'nothing is filtered on screen');
    expect(asked, [(file.path, 3.0)]);

    await tester.pumpWidget(app(3.2));
    await tester.pump();
    expect(asked, hasLength(1), reason: 'the same rounded blur is not made again');
    await tester.pumpWidget(app(0));
    await tester.pump();
    expect((shown().image as FileImage).file.path, file.path, reason: 'no blur: the picture itself');
    expect(tester.takeException(), isNull);
  });

  test('with a background behind, pages and the app bar are see-through; otherwise opaque', () {
    final plain = buildThemeFromColors(colors, false);
    expect(plain.scaffoldBackgroundColor, colors.bg);
    expect(plain.appBarTheme.backgroundColor, colors.bg);
    final over = buildThemeFromColors(colors, false, pageBackdrop: true);
    expect(over.scaffoldBackgroundColor, Colors.transparent);
    expect(over.appBarTheme.backgroundColor, Colors.transparent);
    expect(over.canvasColor, colors.bg, reason: 'menus and dialogs stay solid');
  });
}
