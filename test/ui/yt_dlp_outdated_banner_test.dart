import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/ui/widgets/yt_dlp_outdated_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  Future<void> show(WidgetTester tester, String? version) async {
    final h = await Harness.create(tester);
    await h.pump(
      tester,
      const Scaffold(body: YtDlpOutdatedBanner()),
      extraOverrides: [
        ytDlpStatusProvider.overrideWith((_) async => YtDlpStatus(version)),
      ],
    );
    addTearDown(() => h.dispose(tester));
  }

  testWidgets('an old yt-dlp shows the warning with its version',
      (tester) async {
    await show(tester, '2024.04.09');
    expect(find.textContaining('yt-dlp 2024.04.09 è troppo vecchio'),
        findsOneWidget);
  });

  testWidgets('a recent or unknown yt-dlp shows nothing', (tester) async {
    await show(tester, '2026.08.19');
    expect(find.textContaining('troppo vecchio'), findsNothing);
  });

  testWidgets('an unreadable version is not reported as old', (tester) async {
    await show(tester, null);
    expect(find.textContaining('troppo vecchio'), findsNothing);
  });
}
