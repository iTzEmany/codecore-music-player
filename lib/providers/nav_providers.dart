import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NavTab { home, search, library, memory }

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
  NavIndexNotifier.new,
);

/// One navigator per tab, so pages opened in a tab keep the mini-player and
/// the bottom bar on screen.
final tabNavigatorKeysProvider = Provider<List<GlobalKey<NavigatorState>>>(
  (ref) => [
    for (final t in NavTab.values)
      GlobalKey<NavigatorState>(debugLabel: 'tab-${t.name}'),
  ],
);

/// Right-hand panel of the desktop layout.
enum SidePanel { none, queue, lyrics, info }

class SidePanelNotifier extends Notifier<SidePanel> {
  @override
  SidePanel build() => SidePanel.none;

  /// Once the user has opened or closed a panel by hand, none opens by itself.
  bool chosen = false;

  /// Tapping the open panel's button again closes it.
  void toggle(SidePanel p) {
    chosen = true;
    state = state == p ? SidePanel.none : p;
  }

  void close() {
    chosen = true;
    state = SidePanel.none;
  }

  /// The wide layout opens the queue by itself, unless the user decided.
  void autoOpen() {
    if (chosen || state != SidePanel.none) return;
    state = SidePanel.queue;
  }
}

final sidePanelProvider = NotifierProvider<SidePanelNotifier, SidePanel>(
  SidePanelNotifier.new,
);
