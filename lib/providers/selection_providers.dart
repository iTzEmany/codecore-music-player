import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tracks picked in one list, in the order they were picked, and the one
/// the next range starts from. Immutable: every change returns a new value.
class Selection {
  const Selection({this.ids = const {}, this.anchor});

  static const empty = Selection();

  /// Insertion-ordered (Dart's default `Set`): the order of the picks, which is
  /// the order queue, playlist and the other bulk actions use.
  final Set<int> ids;

  /// The last track picked by hand; Shift+click extends the selection to it.
  final int? anchor;

  bool get active => ids.isNotEmpty;
  int get count => ids.length;
  bool contains(int id) => ids.contains(id);

  /// The picked ids, first pick first.
  List<int> get orderedIds => ids.toList(growable: false);

  /// 0-based place of [id] in the order of the picks, -1 when it is not picked.
  int positionOf(int id) {
    if (!ids.contains(id)) return -1;
    var i = 0;
    for (final x in ids) {
      if (x == id) return i;
      i++;
    }
    return -1;
  }

  Selection toggle(int id) {
    final next = {...ids};
    if (!next.remove(id)) next.add(id);
    return next.isEmpty ? empty : Selection(ids: next, anchor: id);
  }

  /// Adds every track between the anchor and [id] ([visibleIds] is the list as
  /// shown), in the direction of the gesture: downwards from the anchor, or
  /// upwards when [id] is above it. Without a usable anchor it is a plain
  /// [toggle].
  Selection selectRange(List<int> visibleIds, int id) {
    final from = anchor == null ? -1 : visibleIds.indexOf(anchor!);
    final to = visibleIds.indexOf(id);
    if (from < 0 || to < 0) return toggle(id);
    final span = from <= to
        ? visibleIds.sublist(from, to + 1)
        : visibleIds.sublist(to, from + 1).reversed.toList();
    return Selection(ids: {...ids, ...span}, anchor: anchor);
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
