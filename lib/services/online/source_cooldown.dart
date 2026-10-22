import 'query_match.dart';

/// A source that answered «too many requests» is left alone for a while: the
/// next searches do not ask it, the others carry on without it.
class SourceCooldown {
  SourceCooldown({
    this.pause = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration pause;
  final DateTime Function() _now;
  final _until = <MediaKind, DateTime>{};

  /// Leaves [source] alone for [pause] from now.
  void trip(MediaKind source) => _until[source] = _now().add(pause);

  bool isPaused(MediaKind source) {
    final until = _until[source];
    if (until == null) return false;
    if (_now().isBefore(until)) return true;
    _until.remove(source);
    return false;
  }
}
