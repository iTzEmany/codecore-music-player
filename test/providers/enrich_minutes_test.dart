import 'package:flutter_test/flutter_test.dart';

import 'package:codecore/providers/online_providers.dart';

void main() {
  test('enrichMinutes uses the identified pace (3 s per track)', () {
    expect(enrichMinutes(1871), 94);
    expect(enrichMinutes(1), 1);
  });
}
