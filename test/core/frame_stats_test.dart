import 'package:codecore/core/frame_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nearest-rank percentiles', () {
    final v = [for (var i = 1; i <= 10; i++) i.toDouble()];
    expect(percentile(v, 50), 5);
    expect(percentile(v, 90), 9);
    expect(percentile(v, 99), 10);
    expect(percentile(const [], 50), 0);
  });

  test('a frame is late when either thread misses the budget', () {
    final s = summarizeFrames(const [
      FrameSample(2, 3, 6),
      FrameSample(20, 4, 26), // UI thread late at 60 Hz
      FrameSample(5, 9, 15), // late only at 120 Hz
      FrameSample(4, 4, 9),
    ], budgetMs: 1000 / 120);
    expect(s.frames, 4);
    expect(s.over60Hz, 1);
    expect(s.overBudget, 2);
    expect(s.jank60Hz, 0.25);
    expect(s.build, [4, 20, 20]);
    expect(s.raster, [4, 9, 9]);
    expect(s.toJson()['budgetMs'], 8.33);
  });

  test('no frames, no division by zero', () {
    final s = summarizeFrames(const []);
    expect(s.frames, 0);
    expect(s.jank60Hz, 0);
  });
}
