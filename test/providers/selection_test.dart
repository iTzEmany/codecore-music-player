import 'package:codecore/providers/selection_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const visible = [10, 20, 30, 40, 50];

  test('starts empty and inactive', () {
    expect(Selection.empty.active, isFalse);
    expect(Selection.empty.count, 0);
  });

  test('toggle adds, removes, and leaves nothing active when empty', () {
    var s = Selection.empty.toggle(20);
    expect(s.active, isTrue);
    expect(s.contains(20), isTrue);
    expect(s.anchor, 20);
    s = s.toggle(40);
    expect(s.ids, {20, 40});
    expect(s.anchor, 40);
    s = s.toggle(20).toggle(40);
    expect(s.active, isFalse);
    expect(s.anchor, isNull);
  });

  test('a range runs forwards from the anchor, in the order shown', () {
    final s = Selection.empty.toggle(20).selectRange(visible, 40);
    expect(s.ids, {20, 30, 40});
    expect(s.anchor, 20, reason: 'the anchor stays for the next range');
  });

  test('a range runs backwards too', () {
    final s = Selection.empty.toggle(40).selectRange(visible, 10);
    expect(s.ids, {10, 20, 30, 40});
  });

  test('a range keeps what was already picked', () {
    final s = Selection.empty.toggle(50).toggle(10).selectRange(visible, 30);
    expect(s.ids, {50, 10, 20, 30});
  });

  test('a range without an anchor, or from one that is no longer shown, is a toggle', () {
    expect(Selection.empty.selectRange(visible, 30).ids, {30});
    final s = const Selection(ids: {99}, anchor: 99).selectRange(visible, 30);
    expect(s.ids, {99, 30});
    expect(Selection.empty.toggle(20).selectRange(visible, 77).ids, {20, 77});
  });

  test('select all takes what is shown, nothing when nothing is shown', () {
    final s = Selection.empty.toggle(99).selectAll(visible);
    expect(s.ids, visible.toSet());
    expect(s.anchor, 10);
    expect(s.selectAll(const []).active, isFalse);
  });

  test('a filter that hides rows removes them from the selection', () {
    final s = Selection.empty.toggle(10).toggle(20).toggle(30);
    final kept = s.retainWhere({20, 30, 40});
    expect(kept.ids, {20, 30});
    expect(kept.anchor, 30);
    expect(s.retainWhere({10, 20, 30}), same(s), reason: 'nothing to drop');
    expect(s.retainWhere({77}).active, isFalse);
    expect(Selection.empty.toggle(10).toggle(20).retainWhere({10}).anchor, isNull,
        reason: 'the anchor 20 is gone');
  });

  test('the ids come back in the order of the list, not of the clicks', () {
    final s = Selection.empty.toggle(40).toggle(10).toggle(30);
    expect(s.inOrderOf(visible), [10, 30, 40]);
    expect(s.inOrderOf(const [30, 99]), [30]);
  });

  test('each list keeps its own selection, and it is forgotten when unused', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final all = container.listen(selectionProvider('all'), (_, _) {});
    final fav = container.listen(selectionProvider('favorites'), (_, _) {});
    container.read(selectionProvider('all').notifier).toggle(1);
    expect(all.read().ids, {1});
    expect(fav.read().active, isFalse);
    container.read(selectionProvider('all').notifier).clear();
    expect(all.read().active, isFalse);
    all.close();
    expect(container.read(selectionProvider('all')).active, isFalse);
  });
}
