import 'package:codecore/core/memory_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemTotal is read from /proc/meminfo', () {
    expect(memTotalKb('MemTotal:        3735288 kB\nMemFree:          123 kB\n'), 3735288);
    expect(memTotalKb('nothing here'), isNull);
  });

  test('4 GB phones get a smaller image cache, the others Flutter\'s default', () {
    expect(imageCacheBytes(3735288), 48 << 20, reason: 'Mi A3');
    expect(imageCacheBytes(7800000), 100 << 20, reason: 'Motorola edge 40');
    expect(imageCacheBytes(null), 100 << 20);
  });
}
