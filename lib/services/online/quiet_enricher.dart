import 'dart:async';
import 'dart:collection';

import '../../core/app_log.dart';

/// Enriches downloaded songs one at a time, out of sight: no line in the
/// Activity centre and no snackbar for each song. A song added while another
/// waits is never lost (the batch job refuses a second start).
class QuietEnricher {
  QuietEnricher({required this.enrich, this.enabled});

  final Future<void> Function(int trackId) enrich;

  /// Read at each [add]: off = the song is left as it is.
  final bool Function()? enabled;

  final _todo = Queue<int>();
  int? _current;
  bool _disposed = false;
  final _changes = StreamController<Set<int>>.broadcast();

  /// The songs waiting or being enriched.
  Set<int> get pending => {?_current, ..._todo};
  Stream<Set<int>> get changes => _changes.stream;

  void add(int trackId) {
    if (_disposed || !(enabled?.call() ?? true)) return;
    if (_current == trackId || _todo.contains(trackId)) return;
    _todo.add(trackId);
    _changed();
    if (_current == null) unawaited(_drain());
  }

  Future<void> _drain() async {
    while (_todo.isNotEmpty && !_disposed) {
      final id = _current = _todo.removeFirst();
      try {
        await enrich(id);
      } on Object catch (e, st) {
        AppLog.w('enrichment of downloaded track $id failed', e, st);
      }
      _current = null;
      _changed();
    }
  }

  void _changed() {
    if (!_changes.isClosed) _changes.add(pending);
  }

  void dispose() {
    _disposed = true;
    _todo.clear();
    _changes.close();
  }
}
