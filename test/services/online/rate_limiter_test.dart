import 'package:codecore/services/online/http_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('concurrent waits are spaced by minGap, none starts together', () async {
    const gap = Duration(milliseconds: 80);
    final limiter = RateLimiter(minGap: gap);
    final sw = Stopwatch()..start();
    final at = <int>[];
    await Future.wait([
      for (var i = 0; i < 3; i++)
        limiter.wait().then((_) => at.add(sw.elapsedMilliseconds)),
    ]);
    expect(at, hasLength(3));
    for (var i = 1; i < at.length; i++) {
      expect(at[i] - at[i - 1], greaterThanOrEqualTo(gap.inMilliseconds - 15));
    }
  });
}
