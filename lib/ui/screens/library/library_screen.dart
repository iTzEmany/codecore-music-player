import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import 'albums_tab.dart';
import 'artists_tab.dart';
import 'tracks_tab.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [
          Tab(text: context.l10n.tracks),
          Tab(text: context.l10n.albums),
          Tab(text: context.l10n.artists),
        ]),
        Expanded(
          child: TabBarView(
              children: [TracksTab(), AlbumsTab(), ArtistsTab()]),
        ),
      ]),
    );
  }
}
