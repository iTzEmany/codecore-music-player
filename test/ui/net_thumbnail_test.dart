import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:codecore/ui/widgets/net_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: buildThemeFromColors(CcColors.notte, false),
      home: MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 2.75),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('no address: the placeholder only', (tester) async {
    await tester.pumpWidget(_wrap(const NetThumbnail(url: null, width: 80, height: 45, icon: Icons.music_video)));
    expect(find.byIcon(Icons.music_video), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an address: decoded at the size shown, the placeholder stays behind', (tester) async {
    await tester.pumpWidget(_wrap(const NetThumbnail(
        url: 'https://i.ytimg.com/vi/abc/mqdefault.jpg', width: 80, height: 45, icon: Icons.music_video)));
    await tester.pump();
    expect(find.byIcon(Icons.music_video), findsOneWidget, reason: 'until the picture arrives');
    final image = tester.widget<Image>(find.byType(Image)).image;
    expect(image, isA<ResizeImage>().having((r) => r.width, 'width', 220));
    expect(tester.getSize(find.byType(NetThumbnail)), const Size(80, 45));
  });
}
