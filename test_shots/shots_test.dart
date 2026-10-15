import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/ui/screens/jam/jam_screen.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:codecore/ui/shell/app_shell.dart';
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

      testWidgets('jam', (tester) => withShot(tester, size, (s) async {
            await s.show(const JamScreen(),
                extra: [jamProvider.overrideWith(_FakeJam.new)]);
            await s.expectShot('jam');
          }));
    });
  }
}
