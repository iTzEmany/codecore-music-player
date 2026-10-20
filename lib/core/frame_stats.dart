import 'dart:ui' show FrameTiming;

/// One rendered frame, in milliseconds: UI thread (build, layout, paint),
/// raster thread, and from vsync to the frame on screen.
class FrameSample {
  const FrameSample(this.buildMs, this.rasterMs, this.totalMs);

  factory FrameSample.of(FrameTiming t) => FrameSample(
        t.buildDuration.inMicroseconds / 1000,
        t.rasterDuration.inMicroseconds / 1000,
        t.totalSpan.inMicroseconds / 1000,
      );

  final double buildMs, rasterMs, totalMs;
}

/// A burst of frames summed up the way phase 28 measures them: 50th, 90th and
/// 99th percentile of each part, and how many frames missed 60 Hz (16.7 ms)
/// and the display's own budget.
class FrameStats {
  const FrameStats({
    required this.frames,
    required this.build,
    required this.raster,
    required this.total,
    required this.over60Hz,
    required this.overBudget,
    required this.budgetMs,
  });

  final int frames;

  /// p50, p90, p99 in ms.
  final List<double> build, raster, total;
  final int over60Hz, overBudget;
  final double budgetMs;

  /// Share of frames slower than 60 Hz, 0..1.
  double get jank60Hz => frames == 0 ? 0 : over60Hz / frames;

  Map<String, Object> toJson() => {
        'frames': frames,
        'buildMs': build,
        'rasterMs': raster,
        'totalMs': total,
        'over60Hz': over60Hz,
        'overBudget': overBudget,
        'budgetMs': double.parse(budgetMs.toStringAsFixed(2)),
      };
}

const _frame60HzMs = 1000 / 60;

/// Nearest-rank percentile of an ascending list.
double percentile(List<double> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final rank = (p / 100 * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}

/// [budgetMs] is one refresh of the display (8.3 ms at 120 Hz). A frame is
/// late when the UI or the raster thread alone takes longer than that: the
/// two run in parallel on consecutive frames.
FrameStats summarizeFrames(List<FrameSample> frames, {double budgetMs = _frame60HzMs}) {
  List<double> pcts(double Function(FrameSample) of) {
    final v = frames.map(of).toList()..sort();
    return [
      for (final p in const [50.0, 90.0, 99.0])
        double.parse(percentile(v, p).toStringAsFixed(2)),
    ];
  }

  bool late(FrameSample f, double limit) => f.buildMs > limit || f.rasterMs > limit;
  return FrameStats(
    frames: frames.length,
    build: pcts((f) => f.buildMs),
    raster: pcts((f) => f.rasterMs),
    total: pcts((f) => f.totalMs),
    over60Hz: frames.where((f) => late(f, _frame60HzMs)).length,
    overBudget: frames.where((f) => late(f, budgetMs)).length,
    budgetMs: budgetMs,
  );
}
