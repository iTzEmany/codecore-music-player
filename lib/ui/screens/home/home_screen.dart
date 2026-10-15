import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../l10n/l10n_ext.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../library/tracks_tab.dart';
import '../playlists/playlists_screen.dart';
import '../settings/settings_screen.dart';
import '../youtube/youtube_screen.dart';

/// Placeholder Home of task 11.5 (rebuilt in 11.12): title, settings and the
/// shortcuts to what the old tabs used to hold.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    Widget shortcut(IconData icon, String label, Widget page) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => ShellNav.open<void>(context, page),
        );
    Widget titled(String title, Widget body) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: body,
        );
    return Scaffold(
      body: SafeArea(
        child: ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                CcDims.margin, 16, 4, 8),
            child: Row(children: [
              Expanded(
                child: Text(l.navHome,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              IconButton(
                tooltip: l.navSettings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => ShellNav.open<void>(
                    context,
                    Scaffold(
                        appBar: AppBar(title: Text(l.navSettings)),
                        body: const SettingsScreen())),
              ),
            ]),
          ),
          shortcut(Icons.favorite_rounded, l.navFavorites,
              titled(l.navFavorites, const TracksTab(favoritesOnly: true))),
          shortcut(Icons.queue_music_rounded, l.navPlaylists,
              titled(l.navPlaylists, const PlaylistsScreen())),
          if (kEnableYoutube)
            shortcut(Icons.smart_display_outlined, l.youtube,
                titled(l.youtube, const YoutubeScreen())),
        ]),
      ),
    );
  }
}
