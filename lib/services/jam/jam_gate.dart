import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/app_log.dart';
import '../../data/settings/jam_secret_store.dart';

/// A blocked (when = block time) or suspended (when = expiry, null = until the
/// Jam ends) sender.
class JamGateEntry {
  const JamGateEntry(this.id, this.name, this.when);
  final String id, name;
  final DateTime? when;
}

/// Who may ask to join: 2 requests per minute per sender id, plus the
/// suspended and blocked lists, kept in a [JamSecretStore].
class JamGate extends ChangeNotifier {
  JamGate(this._store, {DateTime Function()? now, this.perMinute = 2})
      : _now = now ?? DateTime.now {
    ready = _load();
  }

  final JamSecretStore _store;
  final DateTime Function() _now;
  final int perMinute;

  /// Completes when the saved lists are loaded.
  late final Future<void> ready;

  final _blocked = <String, JamGateEntry>{};
  final _suspended = <String, JamGateEntry>{};
  final _recent = <String, List<DateTime>>{};

  List<JamGateEntry> get blocked => _blocked.values.toList();

  List<JamGateEntry> get suspended {
    _purge();
    return _suspended.values.toList();
  }

  /// Blocked or suspended: its requests are dropped silently.
  bool isMuted(String id) {
    _purge();
    return _blocked.containsKey(id) || _suspended.containsKey(id);
  }

  /// Sliding window of [perMinute] per id; records the attempt when allowed.
  bool allow(String id) {
    final times = _recent.putIfAbsent(id, () => []);
    final cutoff = _now().subtract(const Duration(minutes: 1));
    times.removeWhere((t) => !t.isAfter(cutoff));
    if (times.length >= perMinute) return false;
    times.add(_now());
    return true;
  }

  /// [duration] null: until the end of the Jam.
  void suspend(String id, String name, Duration? duration) {
    _suspended[id] = JamGateEntry(id, name, duration == null ? null : _now().add(duration));
    _changed();
  }

  void unsuspend(String id) {
    if (_suspended.remove(id) != null) _changed();
  }

  void block(String id, String name) {
    _suspended.remove(id);
    _blocked[id] = JamGateEntry(id, name, _now());
    _changed();
  }

  void unblock(String id) {
    if (_blocked.remove(id) != null) _changed();
  }

  /// Drops the suspensions that last until the Jam ends.
  void clearEndOfJam() {
    final before = _suspended.length;
    _suspended.removeWhere((_, e) => e.when == null);
    if (_suspended.length != before) _changed();
  }

  void _purge() {
    final n = _now();
    final before = _suspended.length;
    _suspended.removeWhere((_, e) => e.when != null && e.when!.isBefore(n));
    if (_suspended.length != before) _changed();
  }

  void _changed() {
    notifyListeners();
    _save(jamBlockedKey, _blocked, 'at');
    _save(jamSuspendedKey, _suspended, 'until');
  }

  void _save(String key, Map<String, JamGateEntry> m, String field) {
    final json = jsonEncode([
      for (final e in m.values)
        {'id': e.id, 'name': e.name, field: e.when?.toIso8601String()},
    ]);
    _store.write(key, json).catchError((Object e, StackTrace st) {
      AppLog.w('jam gate: cannot save $key', e, st);
    });
  }

  Future<void> _load() async {
    try {
      _read(await _store.read(jamBlockedKey), 'at', _blocked);
      _read(await _store.read(jamSuspendedKey), 'until', _suspended);
      // "Until the end of the Jam" does not survive a restart.
      clearEndOfJam();
    } on Object catch (e, st) {
      AppLog.w('jam gate: cannot load the lists', e, st);
    }
  }

  static void _read(String? raw, String field, Map<String, JamGateEntry> into) {
    if (raw == null) return;
    for (final e in jsonDecode(raw) as List) {
      final m = e as Map;
      final w = m[field];
      into[m['id'] as String] =
          JamGateEntry(m['id'] as String, m['name'] as String, w is String ? DateTime.tryParse(w) : null);
    }
  }
}
