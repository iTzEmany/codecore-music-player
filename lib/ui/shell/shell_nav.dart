import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/nav_providers.dart';

/// Opens pages inside the tab's own navigator so the mini-player and the
/// bottom bar stay on screen.
abstract final class ShellNav {
  /// In the current tab. Called from a page already inside a tab navigator it
  /// is the same as `Navigator.of(context).push`.
  static Future<T?> open<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));

  /// From anywhere (Now Playing, lyrics, other tabs): closes the routes above
  /// the shell, switches to Library and pushes [page] there.
  static void openInLibrary(BuildContext context, WidgetRef ref, Widget page) {
    final root = Navigator.of(context, rootNavigator: true);
    root.popUntil((r) => r.isFirst);
    ref.read(navIndexProvider.notifier).set(NavTab.library.index);
    final nav = ref
        .read(tabNavigatorKeysProvider)[NavTab.library.index]
        .currentState;
    nav?.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// Same as [openInLibrary] but for the Search tab.
  static void showSearch(BuildContext context, WidgetRef ref) {
    final root = Navigator.of(context, rootNavigator: true);
    root.popUntil((r) => r.isFirst);
    ref.read(navIndexProvider.notifier).set(NavTab.search.index);
  }
}
