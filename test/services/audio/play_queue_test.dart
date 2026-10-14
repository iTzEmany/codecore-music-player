import 'dart:math';

import 'package:codecore/services/audio/play_queue.dart';
import 'package:flutter_test/flutter_test.dart';

PlayQueue make(List<int> ids, {int start = 0}) =>
    PlayQueue(random: Random(7))..setItems(ids, startIndex: start);

void main() {
  test('starts at requested index', () {
    final q = make([10, 20, 30], start: 1);
    expect(q.currentId, 20);
    expect(q.currentIndex, 1);
  });

  test('empty queue', () {
    final q = PlayQueue();
    expect(q.currentId, isNull);
    expect(q.currentIndex, -1);
    expect(q.next(), isNull);
    expect(q.previous(), isNull);
  });

  test('repeat off stops at the end (auto)', () {
    final q = make([1, 2]);
    expect(q.next(auto: true), 2);
    expect(q.next(auto: true), isNull);
    expect(q.currentId, 2);
  });

  test('repeat all wraps', () {
    final q = make([1, 2])..repeat = PlayRepeat.all;
    q.next();
    expect(q.next(auto: true), 1);
  });

  test('repeat one: auto keeps, manual advances', () {
    final q = make([1, 2, 3])..repeat = PlayRepeat.one;
    expect(q.next(auto: true), 1);
    expect(q.next(), 2);
  });

  test('repeat one manual at the end wraps like all', () {
    final q = make([1, 2], start: 1)..repeat = PlayRepeat.one;
    expect(q.next(), 1);
  });

  test('shuffle keeps current first and has no repeats', () {
    final q = make(List.generate(20, (i) => i), start: 5);
    q.shuffle = true;
    expect(q.currentId, 5);
    final seen = <int>{q.currentId!};
    for (var i = 0; i < 19; i++) {
      expect(seen.add(q.next()!), isTrue);
    }
    expect(q.next(), isNull);
  });

  test('shuffle off keeps current and natural order', () {
    final q = make([1, 2, 3, 4], start: 0)..shuffle = true;
    q.next();
    final cur = q.currentId;
    q.shuffle = false;
    expect(q.currentId, cur);
    expect(q.currentIndex, [1, 2, 3, 4].indexOf(cur!));
    expect(q.playOrder, [1, 2, 3, 4]);
  });

  test('previous follows listening history', () {
    final q = make([1, 2, 3, 4]);
    q.next();
    q.jumpTo(3);
    expect(q.currentId, 4);
    expect(q.previous(), 2);
    expect(q.previous(), 1);
  });

  test('previous without history goes to previous item', () {
    final q = make([1, 2, 3], start: 2);
    expect(q.previous(), 2);
    expect(q.previous(), 1);
    expect(q.previous(), 1);
  });

  test('removeAt current reports and points to following', () {
    final q = make([1, 2, 3], start: 1);
    expect(q.removeAt(1), isTrue);
    expect(q.currentId, 3);
    expect(q.items, [1, 3]);
  });

  test('removeAt before current keeps current', () {
    final q = make([1, 2, 3], start: 2);
    expect(q.removeAt(0), isFalse);
    expect(q.currentId, 3);
    expect(q.currentIndex, 1);
  });

  test('removeAt last current clamps', () {
    final q = make([1, 2], start: 1);
    q.removeAt(1);
    expect(q.currentId, 1);
  });

  test('insertNext plays right after current', () {
    final q = make([1, 2, 3]);
    q.insertNext(99);
    expect(q.next(), 99);
    expect(q.next(), 2);
  });

  test('insertNext in shuffle plays next too', () {
    final q = make([1, 2, 3, 4, 5])..shuffle = true;
    q.insertNext(99);
    expect(q.next(), 99);
  });

  test('append goes to the end', () {
    final q = make([1, 2]);
    q.append(7);
    expect(q.items, [1, 2, 7]);
    q.next();
    expect(q.next(), 7);
  });

  test('move keeps current track', () {
    final q = make([1, 2, 3, 4], start: 1);
    q.move(0, 3);
    expect(q.items, [2, 3, 4, 1]);
    expect(q.currentId, 2);
    q.move(0, 2);
    expect(q.items, [3, 4, 2, 1]);
    expect(q.currentId, 2);
    expect(q.next(), 1);
  });
}
