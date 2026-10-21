import 'dart:ui' show DisplayFeatureType;

import '../screens/share/pairing_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';
import '../../providers/nav_providers.dart';
import '../../providers/player_providers.dart';
import '../../providers/preview_providers.dart';
import '../../providers/ui_providers.dart';
import '../../providers/youtube_providers.dart' show ytDlpStatusProvider;
import '../../services/audio/codecore_audio_handler.dart';
import '../screens/library/library_screen.dart';
import '../screens/memory/memory_screen.dart';
import '../screens/share/incoming_offer_dialog.dart';
import '../../providers/jam_providers.dart';
import '../../providers/share_hub.dart';
import '../screens/jam/jam_request_dialog.dart';
import '../screens/search/search_screen.dart';
import '../screens/home/home_screen.dart';
import '../../l10n/l10n_ext.dart';
import '../theme/tokens.dart';
import '../widgets/enrich_result_listener.dart';
import '../widgets/import_event_listener.dart';
import '../widgets/mini_player.dart';
import 'bottom_bar.dart';
import 'desktop_player_bar.dart';
import 'desktop_sidebar.dart';
import 'shell_keys.dart';
import 'side_panel.dart';
import '../widgets/motion.dart';

const _wideBreakpoint = 840.0;

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _space = SingleActivator(LogicalKeyboardKey.space);
  static const _volUp = SingleActivator(
    LogicalKeyboardKey.arrowUp,
    control: true,
  );
  static const _volDown = SingleActivator(
    LogicalKeyboardKey.arrowDown,
    control: true,
  );

  Map<ShortcutActivator, VoidCallback> _shortcuts(WidgetRef ref) {
    final ctrl = ref.read(playerControllerProvider);
    final vol = ref.read(volumeProvider.notifier);

    void bump(double d) =>
        vol.set((ref.read(volumeProvider) + d).clamp(0.0, 1.0));
    return {
      _space: ctrl.togglePlayPause,
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
          ctrl.next,
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
          ctrl.previous,
      // Hardware media keys (delivered to the focused window).
      const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
          ctrl.togglePlayPause,
      const SingleActivator(LogicalKeyboardKey.mediaTrackNext): ctrl.next,
      const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious):
          ctrl.previous,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
        ref.read(navIndexProvider.notifier).set(NavTab.search.index);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(searchFocusProvider).requestFocus(),
        );
      },
      // Ends a 20 s preview started from the menu.
      const SingleActivator(LogicalKeyboardKey.escape): () {
        final preview = ref.read(previewProvider);
        if (preview.active) ref.read(previewProvider.notifier).stop();
      },
      _volUp: () => bump(0.05),
      _volDown: () => bump(-0.05),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Desktop only: starts the yt-dlp version check at launch (Android would
    // have to boot its embedded Python for it).
    if (isDesktop) ref.listen(ytDlpStatusProvider, (_, _) {});
    ref.listen(playerFailuresProvider, (_, next) {
      final f = next.value;
      if (f == null) return;
      final l = context.l10n;
      final reason = switch (f.reason) {
        PlaybackFailureReason.fileMissing => l.reasonFileMissing,
        PlaybackFailureReason.unplayable => l.reasonUnplayable,
        PlaybackFailureReason.notInLibrary => l.reasonNotInLibrary,
        // TODO(31.5): own message (ARB) pending; reuses the generic one.
        PlaybackFailureReason.onlineUnavailable => l.reasonUnplayable,
      };
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(l.playbackError(f.title ?? '', reason))),
        );
    });
    ref.listen(shareOffersProvider, (_, next) {
      final o = next.value;
      if (o == null) return;
      showDialog<void>(
        context: context,
        builder: (_) => IncomingOfferDialog(offer: o),
      );
    });
    ref.listen(pairRequestsProvider, (_, next) {
      final r = next.value;
      if (r == null) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PairRequestDialog(request: r),
      );
    });
    ref.listen(jamRequestsProvider, (_, next) {
      final r = next.value;
      if (r == null) return;
      showDialog<void>(
        context: context,
        builder: (_) => JamRequestDialog(request: r),
      );
    });
    final index = ref.watch(navIndexProvider);
    final keys = ref.watch(tabNavigatorKeysProvider);
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final l = context.l10n;
    void select(int i) {
      if (i == index) {
        keys[i].currentState?.popUntil((r) => r.isFirst);
      } else {
        ref.read(navIndexProvider.notifier).set(i);
      }
    }

    final items = [
      BottomBarItem(Icons.home_outlined, Icons.home_rounded, l.navHome),
      BottomBarItem(Icons.search_rounded, Icons.search_rounded, l.navSearch),
      BottomBarItem(
        Icons.library_music_outlined,
        Icons.library_music_rounded,
        l.navLibrary,
      ),
      BottomBarItem(
        Icons.storage_outlined,
        Icons.storage_rounded,
        l.navMemory,
      ),
    ];
    Widget tab(int i, Widget root) => Navigator(
      key: keys[i],
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => root),
    );
    final body = TabFade(
      index: index,
      child: IndexedStack(
        index: index,
        children: [
          tab(NavTab.home.index, const HomeScreen()),
          tab(NavTab.search.index, const SearchScreen()),
          tab(NavTab.library.index, const LibraryScreen()),
          tab(NavTab.memory.index, const MemoryScreen()),
        ],
      ),
    );
    Widget content;
    if (wide) {
      final width = MediaQuery.sizeOf(context).width;
      final panel = ref.watch(sidePanelProvider);
      final collapsed = width < 1000;
      // Wide windows show the queue from the first track on, until the user
      // closes it (or picks another panel).
      if (width >= CcDims.xlBreakpoint &&
          panel == SidePanel.none &&
          !ref.read(sidePanelProvider.notifier).chosen &&
          ref.watch(currentTrackProvider.select((t) => t.value != null))) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(sidePanelProvider.notifier).autoOpen(),
        );
      }
      // A vertical hinge must not cut the sidebar: the content starts after it.
      final hinge = MediaQuery.displayFeaturesOf(context)
          .where(
            (f) =>
                (f.type == DisplayFeatureType.hinge ||
                    f.type == DisplayFeatureType.fold) &&
                f.bounds.height >= MediaQuery.sizeOf(context).height * 0.9 &&
                f.bounds.width < width / 3,
          )
          .firstOrNull;
      final sidebarWidth = collapsed
          ? CcDims.sidebarCollapsedWidth
          : CcDims.sidebarWidth;
      final inset = hinge != null && hinge.bounds.left < sidebarWidth
          ? hinge.bounds.right
          : 0.0;
      content = Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: inset),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      DesktopSidebar(collapsed: collapsed),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: body),
                            const EnrichResultListener(),
                            const ImportEventListener(),
                          ],
                        ),
                      ),
                      if (panel != SidePanel.none) SidePanelView(panel: panel),
                    ],
                  ),
                ),
                const DesktopPlayerBar(),
              ],
            ),
          ),
        ),
      );
    } else {
      content = Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(child: body),
              const EnrichResultListener(),
              const ImportEventListener(),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            BottomBar(items: items, selected: index, onSelect: select),
          ],
        ),
      );
    }
    // Android back: nested navigator first, then Home, then leave the app.
    content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = keys[index].currentState;
        // maybePop (not pop) so a page's own PopScope, e.g. a selection that
        // Back must end first, is consulted.
        if (nav != null && await nav.maybePop()) {
          return;
        } else if (index != 0) {
          ref.read(navIndexProvider.notifier).set(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: content,
    );
    if (isDesktop) {
      content = ShellKeys(
        bindings: _shortcuts(ref),
        textOnly: const {_space, _volUp, _volDown},
        // Any click ends a preview started from the menu.
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (ref.read(previewProvider).active) {
              ref.read(previewProvider.notifier).stop();
            }
          },
          child: content,
        ),
      );
    }
    return content;
  }
}
