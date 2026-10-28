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

/// True while the phone's dock carries the Search field (on the Search tab).
class SearchBarNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Any way out of Search (a page opened in Library...) closes the field.
    ref.listen(navIndexProvider, (_, tab) {
      if (tab != NavTab.search.index) state = false;
    });
    return false;
  }

  /// Whether the field takes the focus (and the keyboard) when it appears.
  bool focusOnShow = true;

  /// Shows the field above the dock, on the Search tab.
  void open() {
    ref.read(navIndexProvider.notifier).set(NavTab.search.index);
    focusOnShow = true;
    // Already shown with the keyboard hidden by hand: Cerca brings it back.
    // Android Back hides the keyboard but leaves the focus, so drop it first.
    if (state) {
      final focus = ref.read(searchFocusProvider);
      if (focus.hasFocus) focus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
    }
    state = true;
  }

  /// Back to the root of Search from a page: the field returns, no keyboard.
  void reopen() {
    if (ref.read(navIndexProvider) != NavTab.search.index) return;
    focusOnShow = false;
    state = true;
  }

  /// A page opened from Search: the field goes, the text stays.
  void close() {
    ref.read(searchFocusProvider).unfocus();
    state = false;
  }

  /// ✕: forgets the text and hides the keyboard; the field and the tab stay.
  void dismiss() {
    ref.read(searchControllerProvider).clear();
    ref.read(searchFocusProvider).unfocus();
  }
}

final searchBarProvider = NotifierProvider<SearchBarNotifier, bool>(
  SearchBarNotifier.new,
);
