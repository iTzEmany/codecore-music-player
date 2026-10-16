// Golden tests of the main screens at 100 % and 150 % text, phone and desktop.
// Generated and compared on Linux only (fonts and rasterisation differ elsewhere).
//   flutter test --update-goldens test/goldens     # after an intended change
import 'dart:io';

import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/providers/nav_providers.dart';
import 'package:codecore/providers/import_providers.dart' show searchCacheCountProvider;
import 'package:codecore/providers/youtube_providers.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/ui/screens/jam/jam_screen.dart';
import 'package:codecore/ui/screens/library/all_tracks_screen.dart';
import 'package:codecore/ui/screens/onboarding/onboarding_screen.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/widgets/track_row.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
import 'package:codecore/ui/widgets/cover_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_shots/support/shot_harness.dart';
import 'tolerant_comparator.dart';

class _LibraryTab extends NavIndexNotifier {
  @override
  int build() => NavTab.library.index;
}

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

/// Same colour for the same cover key, on every run.
Color _colourOf(String key) {
  var h = 0x811C9DC5;
  for (final c in key.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFF;
  }
  return Color(0xFF000000 | h | 0x303030);
}

void main() {
  // Fonts and rasterisation are only reproducible on one platform.
  if (!Platform.isLinux) return;

  setUpAll(() {
    TolerantComparator.install();
    coverImageStub = (key) => ColoredBox(color: _colourOf(key));
  });
  tearDownAll(() => coverImageStub = null);

  for (final size in ShotSize.values) {
    for (final scale in const [1.0, 1.5]) {
      final tag = '${size.name}_${(scale * 100).round()}';
      group(tag, () {
        testWidgets('library', (tester) => withShot(tester, size, (s) async {
              await s.show(const AppShell(),
                  textScale: scale,
                  extra: [navIndexProvider.overrideWith(_LibraryTab.new)]);
              await s.expectGolden('${tag}_library.png');
            }));

        testWidgets('album', (tester) => withShot(tester, size, (s) async {
              final rows = await tester.runAsync(() => s.h.db.customSelect(
                  "SELECT album_key FROM tracks WHERE album = 'The Wall' LIMIT 1").get());
              final key = rows!.first.read<String>('album_key');
              await s.show(
                  AlbumDetailScreen(
                      album: AlbumSummary(
                          albumKey: key,
                          title: 'The Wall',
                          artist: 'Pink Floyd',
                          variousArtists: false,
                          trackCount: 5,
                          durationMs: 1000000,
                          year: 1979,
                          coverKey: s.seed.coverKeys[key])),
                  textScale: scale);
              await s.expectGolden('${tag}_album.png');
            }));

        testWidgets('now_playing', (tester) => withShot(tester, size, (s) async {
              await tester.runAsync(() => s.h.handler.playQueue(s.seed.trackIds, 12));
              await s.show(const NowPlayingScreen(), textScale: scale);
              await s.expectGolden('${tag}_now_playing.png');
            }));

        testWidgets('settings', (tester) => withShot(tester, size, (s) async {
              await s.show(const SettingsScreen(), textScale: scale, extra: [
                ytDlpStatusProvider
                    .overrideWith((_) async => const YtDlpStatus('2026.08.19')),
                searchCacheCountProvider.overrideWith((_) async => 0),
              ]);
              await s.expectGolden('${tag}_settings.png');
            }));

        testWidgets('selection', (tester) => withShot(tester, size, (s) async {
              await s.show(const AllTracksScreen(), textScale: scale);
              await tester.longPress(find.byType(TrackRow).at(1));
              await tester.tap(find.byType(TrackRow).at(3));
              await s.settle();
              await s.expectGolden('${tag}_selection.png');
            }));

        testWidgets('light_library', (tester) => withShot(tester, size, (s) async {
              await s.show(const AppShell(),
                  textScale: scale,
                  theme: AppThemeId.chiaro,
                  accent: CcAccent.blu,
                  extra: [navIndexProvider.overrideWith(_LibraryTab.new)]);
              await s.expectGolden('${tag}_light_library.png');
            }));

        testWidgets('onboarding', (tester) => withShot(tester, size, (s) async {
              await s.show(const OnboardingScreen(askAudioPermission: true),
                  textScale: scale);
              await tester.tap(find.text('Avanti'));
              await s.settle();
              await s.expectGolden('${tag}_onboarding.png');
            }));

        testWidgets('jam', (tester) => withShot(tester, size, (s) async {
              await s.show(const JamScreen(),
                  textScale: scale,
                  extra: [jamProvider.overrideWith(_FakeJam.new)]);
              await s.expectGolden('${tag}_jam.png');
            }));
      });
    }
  }
}
