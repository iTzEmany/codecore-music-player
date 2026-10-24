import 'package:codecore/providers/selection_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every SelectionKey has its own key, so two lists never share picks', () {
    final keys = SelectionKey.values.map((k) => k.key).toSet();
    expect(keys.length, SelectionKey.values.length);
  });
}
