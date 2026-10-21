import 'package:codecore/services/shuffle_plus/insertion_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays [items] to the end the way the engine counts: returns the places
/// (1-based) where suggestions ended up.
List<int> simulate(int songs, int every) {
  final items = List.generate(songs, (i) => i + 1);
  var next = -1;
  var current = 0;
  var played = 1;
  final places = <int>[];
  while (true) {
    final at = nextInsertion(items, current, played, every);
    if (at != null) {
      items.insert(at, next--);
      places.add(at + 1);
    }
    if (current + 1 >= items.length) return places;
    current++;
    played = items[current] < 0 ? 0 : played + 1;
  }
}

void main() {
  test('every 4: on 12 songs the suggestions fall at places 4, 8 and 12', () {
    expect(simulate(12, 4), [4, 8, 12]);
  });

  test('every 3 and every 10 follow the same rule', () {
    expect(simulate(9, 3).take(3), [3, 6, 9]);
    expect(simulate(30, 10), [10, 20, 30]);
  });

  test('«play next» songs cannot make two: one waiting is enough', () {
    expect(nextInsertion([1, 2, -1, 3, 4], 0, 1, 4), isNull);
    expect(nextInsertion([1, 2, 3, 4, -1], 1, 2, 4), isNull);
  });

  test('a suggestion already behind the current song does not count', () {
    expect(nextInsertion([-1, 1, 2, 3, 4], 1, 1, 4), 4);
  });

  test('the queue ending before the place gives null', () {
    expect(nextInsertion([1, 2, 3], 0, 1, 4), isNull);
    expect(nextInsertion([1, 2, 3, 4], 0, 1, 4), 3, reason: 'one song still follows');
    expect(nextInsertion([1], 0, 1, 4), isNull);
    expect(nextInsertion(const [], -1, 0, 4), isNull);
  });

  test('after many skips the suggestion goes right after the current song', () {
    expect(nextInsertion([1, 2, 3, 4, 5, 6], 2, 9, 4), 3);
  });
}
