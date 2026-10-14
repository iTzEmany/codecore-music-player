import 'package:flutter/material.dart';

import '../../strings_it.dart';
import 'albums_tab.dart';
import 'artists_tab.dart';
import 'tracks_tab.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [
          Tab(text: S.tracks),
          Tab(text: S.albums),
          Tab(text: S.artists),
        ]),
        Expanded(
          child: TabBarView(
              children: [TracksTab(), AlbumsTab(), ArtistsTab()]),
        ),
      ]),
    );
  }
}
