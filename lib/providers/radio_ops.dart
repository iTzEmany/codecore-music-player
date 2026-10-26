import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/radio_repository.dart';
import '../services/radio/radio_station.dart';
import 'activity_log_providers.dart';
import 'activity_providers.dart';
import 'radio_providers.dart';

/// «Le mie radio»: saving, renaming and ordering stations.
class RadioOps {
  RadioOps(this._ref);

  final Ref _ref;

  RadioRepository get _repo => _ref.read(radioRepositoryProvider);

  /// The star: saves the station or, if it was saved, takes it out. [undo]
  /// reverts that.
  Future<Future<void> Function()> toggleSaved(RadioStation s) async {
    final saved = _ref.read(savedRadioIdsProvider).contains(s.id);
    saved ? await _repo.remove(s.id) : await _repo.save(s);
    return () => saved ? _repo.save(s) : _repo.remove(s.id);
  }

  /// The daily re-read of the saved stations. A real request shows in the
  /// Activity centre and leaves a line in the Registro, failed or not.
  Future<bool> refreshSaved() async {
    final ok = await _ref.read(radioRefreshProvider)();
    if (!_ref.read(radioCheckingProvider)) return ok;
    _ref.read(radioCheckingProvider.notifier).set(false);
    await _ref
        .read(activityLogProvider.notifier)
        .add(
          LogEntry(
            at: DateTime.now(),
            item: ActivityItem(
              kind: ActivityKind.radio,
              key: 'radio',
              name: null,
              running: false,
              failed: !ok,
            ),
          ),
        );
    return ok;
  }

  Future<void> rename(String id, String name) => _repo.rename(id, name);

  Future<void> saveManual(String name, String address) =>
      _repo.saveManual(name, address);

  /// Throws if the write fails: the caller says so.
  Future<void> reorder(List<String> ids) => _repo.reorder(ids);
}

final radioOpsProvider = Provider<RadioOps>(RadioOps.new);
