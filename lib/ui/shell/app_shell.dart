import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../providers/nav_providers.dart';
import '../../providers/player_providers.dart';
import '../../providers/ui_providers.dart';
import '../screens/library/library_screen.dart';
import '../screens/placeholder_screen.dart';
import '../strings_it.dart';
import '../widgets/mini_player.dart';

const _wideBreakpoint = 840.0;

class _Destination {
  const _Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _destinations = [
  _Destination(S.library, Icons.library_music),
  _Destination(S.favorites, Icons.favorite),
  _Destination(S.playlists, Icons.queue_music),
  _Destination(S.settings, Icons.settings),
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
    final index = ref.watch(navIndexProvider);
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    void select(int i) => ref.read(navIndexProvider.notifier).set(i);
    final body = IndexedStack(index: index, children: const [
      LibraryScreen(),
      PlaceholderScreen(title: S.favorites),
      PlaceholderScreen(title: S.playlists),
      PlaceholderScreen(title: S.settings),
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
                for (final d in _destinations)
                  NavigationRailDestination(
                      icon: Icon(d.icon), label: Text(d.label)),
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
                for (final d in _destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
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
