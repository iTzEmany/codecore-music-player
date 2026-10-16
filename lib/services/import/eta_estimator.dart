/// Remaining time of an import from how long its rows have been taking.
///
/// A sample is the time between two finished rows (searched, downloaded or
/// failed), so parallel downloads are counted for what they really deliver.
/// Rows linked from the library cost nothing and are left out, and a pause
/// never counts as time spent on a row.
class EtaEstimator {
  EtaEstimator({this.alpha = 0.3, this.minSamples = 3, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  /// Weight of the newest sample in the moving average.
  final double alpha;

  /// Samples needed before an estimate is given.
  final int minSamples;
  final DateTime Function() _now;

  DateTime? _last;
  double? _avgMs;
  int _samples = 0;

  int get samples => _samples;

  /// The import starts or resumes: the clock for the next row starts here.
  void start() => _last = _now();

  /// The import is paused or waiting for the user.
  void pause() => _last = null;

  /// A row is done. [linked] rows (already in the library) only move the
  /// clock; the first row after a pause does too, since its start is unknown.
  void rowDone({bool linked = false}) {
    final now = _now();
    final last = _last;
    _last = now;
    if (linked || last == null) return;
    final ms = now.difference(last).inMilliseconds.toDouble();
    _avgMs = _avgMs == null ? ms : alpha * ms + (1 - alpha) * _avgMs!;
    _samples++;
  }

  /// Time for [left] more rows; null until there are enough samples.
  Duration? remaining(int left) {
    final avg = _avgMs;
    if (avg == null || _samples < minSamples || left <= 0) return null;
    return Duration(milliseconds: (avg * left).round());
  }
}
