import 'package:codecore/providers/shuffle_plus_providers.dart';
import 'package:codecore/services/shuffle_plus/plus_allowed.dart';
import 'package:flutter_test/flutter_test.dart';

ShufflePlusBlock? _allowed({
  List<int> queue = const [1, 2, 3, 4, 5],
  bool jam = false,
  bool radio = false,
  int? local,
}) => plusAllowed(
  queueIds: queue,
  jam: jam,
  radio: radio,
  localCount: local ?? queue.where((i) => i > 0).length,
);

void main() {
  test('an online album queue is blocked', () {
    expect(_allowed(queue: [-1, -2, -3, -4, -5, -6]), ShufflePlusBlock.online);
  });
  test('a Jam and a radio are blocked', () {
    expect(_allowed(jam: true), ShufflePlusBlock.jam);
    expect(_allowed(radio: true), ShufflePlusBlock.radio);
  });
  test('a Jam wins over a radio', () {
    expect(_allowed(jam: true, radio: true), ShufflePlusBlock.jam);
  });
  test('fewer than 5 local tracks is blocked, 5 is allowed', () {
    expect(_allowed(queue: [1, 2, 3, 4]), ShufflePlusBlock.shortList);
    expect(_allowed(queue: [1, 2, 3, 4, 5]), isNull);
  });
  test('a mixed queue counts only the local tracks', () {
    expect(
      _allowed(queue: [1, 2, -1, -2, -3], local: 2),
      ShufflePlusBlock.shortList,
    );
  });
  test('an empty queue allows it (the Home picks the mode before Play)', () {
    expect(_allowed(queue: []), isNull);
  });
}
