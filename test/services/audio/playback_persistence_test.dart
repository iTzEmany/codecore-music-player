import 'package:codecore/services/audio/playback_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('library-only queues are saved as they are', () {
    final q = savedQueue([5, 6, 7], 1);
    expect(q.ids, [5, 6, 7]);
    expect(q.index, 1);
  });

  test('an online entry in the middle is dropped and the index follows', () {
    final q = savedQueue([5, -1, 6, 7], 2);
    expect(q.ids, [5, 6, 7]);
    expect(q.index, 1); // still pointing to 6
  });

  test('current online entry: the index points to the library track after it', () {
    final q = savedQueue([5, -1, 6, 7], 1);
    expect(q.ids, [5, 6, 7]);
    expect(q.index, 1);
  });

  test('an online entry at the end: index clamps to the last kept track', () {
    final q = savedQueue([5, 6, -1], 2);
    expect(q.ids, [5, 6]);
    expect(q.index, 1);
  });

  test('only online entries save an empty queue', () {
    final q = savedQueue([-1, -2], 0);
    expect(q.ids, isEmpty);
    expect(q.index, 0);
  });
}
