import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nav_providers.dart';

/// Shared so Ctrl+F in the shell can focus the tracks search field.
final searchFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'search');
  ref.onDispose(node.dispose);
  return node;
});

/// The Search text, shared by the dock's field (phone), the desktop field in
/// `SearchScreen` and the page that reads it.
final searchControllerProvider = Provider<TextEditingController>((ref) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

/// «Online» chip of Search (false: «In libreria»).
class SearchOnlineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool online) => state = online;
}

final searchOnlineProvider = NotifierProvider<SearchOnlineNotifier, bool>(
  SearchOnlineNotifier.new,
);

/// Counts the submits (Enter) of the dock's field; `SearchScreen` runs them.
class SearchSubmitNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void submit() => state++;
}

final searchSubmitProvider = NotifierProvider<SearchSubmitNotifier, int>(
  SearchSubmitNotifier.new,
);

/// True while the phone's dock is the Search field.
class SearchBarNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Any way out of Search (a page opened in Library...) closes the field.
    ref.listen(navIndexProvider, (_, tab) {
      if (tab != NavTab.search.index) state = false;
    });
    return false;
  }

  // The tab ✕ goes back to; never Search itself.
  int _previous = NavTab.home.index;

  /// Turns the dock into the field, on the Search tab.
  void open() {
    final nav = ref.read(navIndexProvider.notifier);
    final current = ref.read(navIndexProvider);
    if (current != NavTab.search.index) _previous = current;
    nav.set(NavTab.search.index);
    state = true;
  }

  /// Back: the tabs return, Search stays with its text.
  void close() {
    ref.read(searchFocusProvider).unfocus();
    state = false;
  }

  /// ✕: forgets the text and goes back to the previous tab.
  void dismiss() {
    ref.read(searchControllerProvider).clear();
    ref.read(searchFocusProvider).unfocus();
    state = false;
    ref.read(navIndexProvider.notifier).set(_previous);
  }
}

final searchBarProvider = NotifierProvider<SearchBarNotifier, bool>(
  SearchBarNotifier.new,
);
