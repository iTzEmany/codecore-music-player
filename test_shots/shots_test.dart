import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/ui/screens/jam/jam_screen.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:codecore/data/repositories/play_history_repository.dart';
import 'package:codecore/ui/screens/library/all_tracks_screen.dart';
import 'package:codecore/ui/screens/stats/stats_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

import 'support/shot_harness.dart';

class _FakeJam extends JamController {
  @override
  JamUiState build() => const JamUiState(
        phase: JamPhase.active,
        role: JamRole.host,
        peerName: 'Telefono di Anna',
        peerId: 'peer',
        jam: JamState(
          version: 3,
          items: [
            JamItem(id: 1, ownerDeviceId: 'host', title: 'Futura', ext: 'mp3',
                artist: 'Lucio Dalla', durationMs: 180000),
            JamItem(id: 2, ownerDeviceId: 'peer', title: 'Get Lucky', ext: 'mp3',
                artist: 'Daft Punk', durationMs: 248000),
          ],
          currentIndex: 0,
          playing: true,
          hostDeviceId: 'host',
          outputDeviceId: 'host',
        ),
      );
}

void main() {
  for (final size in ShotSize.values) {
    group(size.name, () {
      testWidgets('library', (tester) => withShot(tester, size, (s) async {
            await s.show(const AppShell());
            await s.expectShot('library');
          }));

      testWidgets('album', (tester) => withShot(tester, size, (s) async {
            final albums = await tester.runAsync(
                () => s.h.db.customSelect(
                    "SELECT album_key FROM tracks WHERE album = 'The Wall' LIMIT 1").get());
            final key = albums!.first.read<String>('album_key');
            await s.show(AlbumDetailScreen(
                album: AlbumSummary(
                    albumKey: key,
                    title: 'The Wall',
                    artist: 'Pink Floyd',
                    variousArtists: false,
                    trackCount: 5,
                    durationMs: 1000000,
                    year: 1979,
                    coverKey: s.seed.coverKeys[key])));
            await s.expectShot('album');
          }));

      testWidgets('shell_playing', (tester) => withShot(tester, size, (s) async {
            await tester.runAsync(
                () => s.h.handler.playQueue(s.seed.trackIds, 3));
            await s.show(const AppShell());
            await s.expectShot('shell_playing');
          }));

      testWidgets('now_playing', (tester) => withShot(tester, size, (s) async {
            await tester.runAsync(
                () => s.h.handler.playQueue(s.seed.trackIds, 12));
            await s.show(const NowPlayingScreen());
            await s.expectShot('now_playing');
          }));

      testWidgets('settings', (tester) => withShot(tester, size, (s) async {
            await s.show(const SettingsScreen());
            await s.expectShot('settings');
          }));

      testWidgets('library_light', (tester) => withShot(tester, size, (s) async {
            await s.show(const AppShell(), theme: AppThemeId.chiaro);
            await s.expectShot('library_light');
          }));

      testWidgets('now_playing_light', (tester) => withShot(tester, size, (s) async {
            await tester.runAsync(
                () => s.h.handler.playQueue(s.seed.trackIds, 12));
            await s.show(const NowPlayingScreen(),
                theme: AppThemeId.chiaro, accent: CcAccent.verde);
            await s.expectShot('now_playing_light');
          }));

      testWidgets('shell_playing_light', (tester) => withShot(tester, size, (s) async {
            await tester.runAsync(
                () => s.h.handler.playQueue(s.seed.trackIds, 3));
            await s.show(const AppShell(),
                theme: AppThemeId.chiaro, accent: CcAccent.arancio);
            await s.expectShot('shell_playing_light');
          }));

      testWidgets('settings_light', (tester) => withShot(tester, size, (s) async {
            await s.show(const SettingsScreen(),
                theme: AppThemeId.chiaro, accent: CcAccent.rosa);
            await s.expectShot('settings_light');
          }));

      testWidgets('all_tracks_selection', (tester) => withShot(tester, size, (s) async {
            await s.show(const AllTracksScreen(),
                theme: AppThemeId.chiaro, accent: CcAccent.blu);
            await tester.longPress(find.byType(TrackRow).at(1));
            await tester.tap(find.byType(TrackRow).at(3));
            await s.settle();
            await s.expectShot('all_tracks_selection');
          }));

      testWidgets('all_tracks_selection_dark', (tester) => withShot(tester, size, (s) async {
            await s.show(const AllTracksScreen());
            await tester.longPress(find.byType(TrackRow).at(1));
            await tester.tap(find.byType(TrackRow).at(3));
            await s.settle();
            await s.expectShot('all_tracks_selection_dark');
          }));

      // Widths of docs/fase-19 §19.7: the sidebar folds at 1000, the queue
      // opens by itself from 1200.
      if (size == ShotSize.desktop) {
        for (final w in [840.0, 1000.0, 1200.0, 1600.0]) {
          testWidgets('wide_${w.round()}',
              (tester) => withShot(tester, size, (s) async {
                    tester.view.physicalSize = Size(w, w < 1200 ? 800 : 900);
                    await tester.runAsync(
                        () => s.h.handler.playQueue(s.seed.trackIds, 3));
                    await s.show(const AppShell());
                    await s.expectShot('shell_wide_${w.round()}');
                  }));
        }
      }

      testWidgets('stats', (tester) => withShot(tester, size, (s) async {
            final repo = PlayHistoryRepository(s.h.db);
            final ids = s.seed.trackIds;
            await tester.runAsync(() async {
              for (var d = 1; d <= 16; d++) {
                for (var k = 0; k < 1 + d % 4; k++) {
                  await repo.start(ids[(d + k) % ids.length],
                      DateTime(2026, 10, d, 18 + k, 20).millisecondsSinceEpoch,
                      msPlayed: (2 + (d * 7 + k * 3) % 5) * 60000);
                }
              }
            });
            await s.show(StatsScreen(now: DateTime(2026, 10, 16, 9)));
            await s.expectShot('stats');
          }));

      testWidgets('jam', (tester) => withShot(tester, size, (s) async {
            await s.show(const JamScreen(),
                extra: [jamProvider.overrideWith(_FakeJam.new)]);
            await s.expectShot('jam');
          }));
    });
  }
}
