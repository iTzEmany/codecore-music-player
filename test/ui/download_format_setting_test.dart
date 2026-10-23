import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/ui/screens/settings/download_settings_tiles.dart';
import 'package:codecore/ui/widgets/segmented_blocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets(
    'the format row shows M4A; the list explains the four formats and saves the pick',
    (tester) async {
      final h = await Harness.create(tester);
      await h.pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(child: DownloadSettingsTiles()),
        ),
      );
      expect(find.text('Formato dei download'), findsOneWidget);
      expect(find.text('M4A (consigliato)'), findsOneWidget);

      await tester.tap(find.text('Formato dei download'));
      await tester.pumpAndSettle();
      for (final label in [
        'Originale (qualità massima)',
        'MP3 320 kbps',
        'MP3 192 kbps (qualità minima)',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(
        find.textContaining('senza ricodifica'),
        findsOneWidget,
        reason: 'only the selected hint shows',
      );
      expect(find.byType(SegmentedBlocks<DownloadFormat>), findsOneWidget);

      await tester.tap(find.text('MP3 320 kbps'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Applica'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DownloadSettingsTiles)),
      );
      expect(
        container.read(settingsProvider).downloadFormat,
        DownloadFormat.mp3High,
      );
      expect(
        find.text('MP3 320 kbps'),
        findsOneWidget,
        reason: 'the row shows the new choice',
      );
      expect(h.store.readSettings().downloadFormat, DownloadFormat.mp3High);
      await h.dispose(tester);
    },
  );
}
