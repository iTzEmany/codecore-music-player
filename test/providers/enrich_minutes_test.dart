import 'package:flutter_test/flutter_test.dart';

import 'package:codecore/providers/online_providers.dart';

void main() {
  test('enrichMinutes uses the anonymous Wikimedia pace (40 s per track)', () {
    expect(enrichMinutes(1871), 1248);
    expect(enrichMinutes(1), 1);
  });
}
