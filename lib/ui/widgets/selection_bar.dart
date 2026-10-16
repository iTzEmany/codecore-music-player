import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/nav_providers.dart';
import '../../providers/selection_providers.dart';
import '../theme/tokens.dart';
import 'bulk_actions.dart';
import 'track_actions.dart';

/// The bar that takes the place of a page's header while tracks are picked:
/// «N selezionati», select all, ✕, the quick actions and the full menu.
class SelectionBar extends ConsumerWidget implements PreferredSizeWidget {
  const SelectionBar({
    super.key,
    required this.listKey,
    required this.tracks,
    this.bulk = const BulkContext(),
  });

  final String listKey;

  /// Every track the list shows, in order.
  final List<Track> tracks;
  final BulkContext bulk;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final selection = ref.watch(selectionProvider(listKey));
    final notifier = ref.read(selectionProvider(listKey).notifier);
    final picked = [
      for (final t in tracks)
        if (selection.contains(t.id)) t,
    ];
    final groups = bulkActions(
      context,
      ref,
      picked,
      bulk,
      done: notifier.clear,
    );
    // The two most used actions stay in the bar, the rest are in the menu.
    final quick = [
      for (final g in groups)
        for (final a in g.actions)
          if (a.icon == Icons.playlist_add_rounded ||
              a.icon == Icons.favorite_rounded ||
              a.icon == Icons.favorite_border_rounded)
            a,
    ];
    return Material(
      color: cc.surface2,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              IconButton(
                tooltip: l.exitSelection,
                icon: const Icon(Icons.close_rounded),
                onPressed: notifier.clear,
              ),
              Expanded(
                child: Text(
                  l.selectedCount(selection.count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l.selectAll,
                icon: const Icon(Icons.select_all_rounded),
                onPressed: () =>
                    notifier.selectAll([for (final t in tracks) t.id]),
              ),
              for (final a in quick)
                IconButton(
                  tooltip: a.label,
                  icon: Icon(a.icon),
                  onPressed: picked.isEmpty ? null : a.run,
                ),
              PopupMenuButton<TrackAction>(
                tooltip: l.bulkActions,
                enabled: picked.isNotEmpty,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (a) => a.run(),
                itemBuilder: (_) => [
                  for (var g = 0; g < groups.length; g++) ...[
                    if (g > 0) const PopupMenuDivider(),
                    for (final a in groups[g].actions)
                      PopupMenuItem<TrackAction>(
                        value: a,
                        child: Row(
                          children: [
                            Icon(a.icon, size: 20),
                            const SizedBox(width: 12),
                            Flexible(child: Text(a.label)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a list page: Back (phone) and Esc (desktop) leave the selection,
/// Ctrl+A picks everything shown, a filter that hides rows drops them from the
/// selection, and so does changing tab.
class SelectionScope extends ConsumerStatefulWidget {
  const SelectionScope({
    super.key,
    required this.listKey,
    required this.visibleIds,
    required this.child,
  });

  final String listKey;

  /// The ids the list shows now, in order.
  final List<int> visibleIds;
  final Widget child;

  @override
  ConsumerState<SelectionScope> createState() => _SelectionScopeState();
}

class _SelectionScopeState extends ConsumerState<SelectionScope> {
  bool _listening = false;

  SelectionNotifier get _notifier =>
      ref.read(selectionProvider(widget.listKey).notifier);

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _notifier.clear();
      return true;
    }
    final ctrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyA) {
      _notifier.selectAll(widget.visibleIds);
      return true;
    }
    return false;
  }

  void _listen(bool on) {
    if (on == _listening) return;
    _listening = on;
    if (on) {
      HardwareKeyboard.instance.addHandler(_onKey);
    } else {
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
  }

  @override
  void didUpdateWidget(SelectionScope old) {
    super.didUpdateWidget(old);
    if (old.visibleIds != widget.visibleIds) {
      final visible = widget.visibleIds.toSet();
      // Not while building: the selection is watched by the rows.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifier.retainWhere(visible);
      });
    }
  }

  @override
  void dispose() {
    _listen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(
      selectionProvider(widget.listKey).select((s) => s.active),
    );
    ref.listen(navIndexProvider, (_, _) => _notifier.clear());
    // The handler is only kept while something is selected.
    _listen(active);
    return PopScope(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _notifier.clear();
      },
      child: widget.child,
    );
  }
}
