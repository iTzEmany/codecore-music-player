import 'package:codecore/services/import/import_chain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the block number is read from the name, the rest is the import', () {
    expect(blockOf('Liked Songs (3/23)'), (name: 'Liked Songs', part: 3, parts: 23));
    expect(blockOf('Mood'), isNull);
    expect(blockOf('Live (1977)'), isNull, reason: 'a year in brackets is not a block');
    expect(importLabel('Liked Songs (23/23)'), 'Liked Songs');
    expect(importLabel('Mood'), 'Mood');
  });
}
