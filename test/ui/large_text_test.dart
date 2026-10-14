import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/screens/playlists/playlists_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:codecore/ui/screens/share/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  final screens = <String, Widget>{
    'settings': const Scaffold(body: SettingsScreen()),
    'playlists': const PlaylistsScreen(),
    'share': const ShareScreen(),
    'now playing': const NowPlayingScreen(),
  };
  for (final e in screens.entries) {
    testWidgets('${e.key} has no overflow at 150% text', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await Harness.create(tester, tracks: 2);
      final rows = await tester.runAsync(() => h.db.select(h.db.tracks).get());
      await tester.runAsync(
          () => h.handler.playQueue(rows!.map((t) => t.id).toList(), 0));
      await h.pump(
        tester,
        MediaQuery(
          data: MediaQueryData(
              size: const Size(400, 800),
              textScaler: const TextScaler.linear(1.5)),
          child: e.value,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await h.dispose(tester);
    });
  }
}
