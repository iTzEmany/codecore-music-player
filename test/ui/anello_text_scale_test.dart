import 'package:codecore/ui/screens/jam/jam_screen.dart';
import 'package:codecore/ui/screens/library/all_tracks_screen.dart';
import 'package:codecore/ui/screens/library/review_screen.dart';
import 'package:codecore/ui/screens/memory/memory_screen.dart';
import 'package:codecore/ui/screens/now_playing/queue_sheet.dart';
import 'package:codecore/ui/screens/podcast/podcast_detail_screen.dart';
import 'package:codecore/ui/screens/podcast/podcasts_screen.dart';
import 'package:codecore/ui/screens/releases/new_releases_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:codecore/ui/screens/stats/stats_screen.dart';
import 'package:codecore/ui/screens/tags/tags_screen.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// Every screen of the redesign at 150 % text, 360x780, in the three themes:
/// nothing may overflow. Search and the online artist page belong to plan 2.4.
void main() {
  final themes = <String, CcColors>{
    'Notte viola': CcColors.notte.copyWith(accent: const Color(0xFF9B7BFF)),
    'OLED ambra': CcColors.oled.copyWith(accent: const Color(0xFFFFB300)),
    'Chiaro rosa': CcColors.chiaro.copyWith(accent: const Color(0xFFE91E63)),
  };
  final screens = <String, Widget Function()>{
    'Stats': () => const StatsScreen(),
    'Review': () => const ReviewScreen(),
    'NewReleases': () => const NewReleasesScreen(),
    'Podcasts': () => const PodcastsScreen(),
    'PodcastDetail': () => const PodcastDetailScreen(podcastId: 1),
    'Memory': () => const MemoryScreen(),
    'TagTracks': () => const TagTracksScreen(name: 'Live'),
    'QueueSheet': () => QueueSheet(scrollController: ScrollController()),
    'Jam': () => const JamScreen(),
    'AllTracks': () => const AllTracksScreen(),
    'Settings': () => const SettingsScreen(),
  };
  for (final t in themes.entries) {
    for (final s in screens.entries) {
      testWidgets('${s.key} at 150 % in ${t.key}', (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final h = await Harness.create(tester, tracks: 3);
        await h.pump(tester, Scaffold(body: s.value()), textScale: 1.5, colors: t.value);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        await h.dispose(tester);
      });
    }
  }
}
