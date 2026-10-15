import 'package:codecore/data/repositories/library_queries.dart';
import 'package:codecore/ui/screens/home/home_screen.dart';
import 'package:codecore/ui/screens/library/album_detail_screen.dart';
import 'package:codecore/ui/screens/library/all_tracks_screen.dart';
import 'package:codecore/ui/screens/library/artist_screen.dart';
import 'package:codecore/ui/screens/library/favorites_screen.dart';
import 'package:codecore/ui/screens/library/library_screen.dart';
import 'package:codecore/ui/screens/now_playing/now_playing_screen.dart';
import 'package:codecore/ui/screens/now_playing/queue_sheet.dart';
import 'package:codecore/ui/screens/search/search_screen.dart';
import 'package:codecore/ui/screens/playlists/playlists_screen.dart';
import 'package:codecore/ui/screens/settings/settings_screen.dart';
import 'package:codecore/ui/screens/share/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _Queue extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      QueueSheet(scrollController: ScrollController());
}

void main() {
  final screens = <String, Widget>{
    'settings': const Scaffold(body: SettingsScreen()),
    'playlists': const PlaylistsScreen(),
    'share': const ShareScreen(),
    'now playing': const NowPlayingScreen(),
    'home': const HomeScreen(),
    'library': const Scaffold(body: LibraryScreen()),
    'search': const SearchScreen(),
    'all tracks': const AllTracksScreen(),
    'album': const AlbumDetailScreen(
        album: AlbumSummary(
      albumKey: 'artist|album 0',
      title: 'Album 0 with a rather long title to wrap on two lines',
      artist: 'Artist',
      variousArtists: false,
      trackCount: 1,
      durationMs: 185000,
      year: 2020,
      coverKey: null,
    )),
    'artist': const ArtistDetailScreen(
        artist: ArtistSummary(
            key: 'artist', name: 'Artist', trackCount: 2, albumCount: 2)),
    'favourites': const FavoritesScreen(),
    'queue': Scaffold(body: _Queue()),
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
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await h.dispose(tester);
    });
  }
}
