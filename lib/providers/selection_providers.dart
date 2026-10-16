import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tracks picked in one list, and the one the next range starts from.
/// Immutable: every change returns a new value.
class Selection {
  const Selection({this.ids = const {}, this.anchor});

  static const empty = Selection();

  final Set<int> ids;

  /// The last track picked by hand; Shift+click extends the selection to it.
  final int? anchor;

  bool get active => ids.isNotEmpty;
  int get count => ids.length;
  bool contains(int id) => ids.contains(id);

  Selection toggle(int id) {
    final next = {...ids};
    if (!next.remove(id)) next.add(id);
    return next.isEmpty ? empty : Selection(ids: next, anchor: id);
  }

  /// Adds every track between the anchor and [id], in the order they are
  /// shown ([visibleIds]). Without a usable anchor it is a plain [toggle].
  Selection selectRange(List<int> visibleIds, int id) {
    final from = anchor == null ? -1 : visibleIds.indexOf(anchor!);
    final to = visibleIds.indexOf(id);
    if (from < 0 || to < 0) return toggle(id);
    final lo = from < to ? from : to;
    final hi = from < to ? to : from;
    return Selection(
      ids: {...ids, ...visibleIds.sublist(lo, hi + 1)},
      anchor: anchor,
    );
  }

  Selection selectAll(List<int> visibleIds) => visibleIds.isEmpty
      ? empty
      : Selection(
          ids: visibleIds.toSet(),
          anchor: anchor != null && visibleIds.contains(anchor)
              ? anchor
              : visibleIds.first,
        );

  /// Drops what a filter has hidden.
  Selection retainWhere(Set<int> stillVisible) {
    final kept = ids.where(stillVisible.contains).toSet();
    if (kept.length == ids.length) return this;
    if (kept.isEmpty) return empty;
    return Selection(ids: kept, anchor: kept.contains(anchor) ? anchor : null);
  }

  /// [ids] in the order of [visibleIds] (the order of the list, not of the
  /// clicks); picked tracks that are not shown any more are left out.
  List<int> inOrderOf(List<int> visibleIds) =>
      [for (final id in visibleIds) if (ids.contains(id)) id];
}

class SelectionNotifier extends Notifier<Selection> {
  SelectionNotifier(this.listKey);

  /// `all`, `favorites`, `album:<key>`, `playlist:<id>`, `search`, `youtube`…
  final String listKey;

  @override
  Selection build() => Selection.empty;

  void toggle(int id) => state = state.toggle(id);
  void selectRange(List<int> visibleIds, int id) =>
      state = state.selectRange(visibleIds, id);
  void selectAll(List<int> visibleIds) => state = state.selectAll(visibleIds);
  void retainWhere(Set<int> stillVisible) =>
      state = state.retainWhere(stillVisible);
  void clear() => state = Selection.empty;
}

/// One selection per list, forgotten when its page goes away.
final selectionProvider = NotifierProvider.autoDispose
    .family<SelectionNotifier, Selection, String>(SelectionNotifier.new);
