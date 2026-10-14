import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../providers/nav_providers.dart';
import '../../providers/player_providers.dart';
import '../../providers/ui_providers.dart';
import '../../services/audio/codecore_audio_handler.dart';
import '../screens/library/library_screen.dart';
import '../screens/library/tracks_tab.dart';
import '../screens/playlists/playlists_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../../l10n/l10n_ext.dart';
import '../widgets/mini_player.dart';

const _wideBreakpoint = 840.0;

const _icons = [
  Icons.library_music,
  Icons.favorite,
  Icons.queue_music,
  Icons.settings,
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts(WidgetRef ref) {
    final ctrl = ref.read(playerControllerProvider);
    final vol = ref.read(volumeProvider.notifier);
    void guarded(VoidCallback f) {
      if (!_typing()) f();
    }

    void bump(double d) =>
        vol.set((ref.read(volumeProvider) + d).clamp(0.0, 1.0));
    return {
      const SingleActivator(LogicalKeyboardKey.space): () =>
          guarded(ctrl.togglePlayPause),
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
          ctrl.next,
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
          ctrl.previous,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
        ref.read(navIndexProvider.notifier).set(0);
        ref.read(searchFocusProvider).requestFocus();
      },
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          guarded(() => bump(0.05)),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          guarded(() => bump(-0.05)),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(playerFailuresProvider, (_, next) {
      final f = next.value;
      if (f == null) return;
      final l = context.l10n;
      final reason = switch (f.reason) {
        PlaybackFailureReason.fileMissing => l.reasonFileMissing,
        PlaybackFailureReason.unplayable => l.reasonUnplayable,
        PlaybackFailureReason.notInLibrary => l.reasonNotInLibrary,
      };
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            SnackBar(content: Text(l.playbackError(f.title ?? '', reason))));
    });
    final index = ref.watch(navIndexProvider);
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    void select(int i) => ref.read(navIndexProvider.notifier).set(i);
    final l = context.l10n;
    final labels = [l.navLibrary, l.navFavorites, l.navPlaylists, l.navSettings];
    final body = IndexedStack(index: index, children: [
      LibraryScreen(),
      TracksTab(favoritesOnly: true),
      PlaylistsScreen(),
      SettingsScreen(),
    ]);
    Widget content = Scaffold(
      body: SafeArea(
        child: Row(children: [
          if (wide)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationRailDestination(
                      icon: Icon(_icons[i]), label: Text(labels[i])),
              ],
            ),
          Expanded(
            child: Column(children: [
              Expanded(child: body),
              const MiniPlayer(),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(_icons[i]), label: labels[i]),
              ],
            ),
    );
    if (isDesktop) {
      content = CallbackShortcuts(
        bindings: _shortcuts(ref),
        child: Focus(autofocus: true, child: content),
      );
    }
    return content;
  }
}
