import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/radio_repository.dart';
import '../services/radio/radio_station.dart';
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

  Future<void> rename(String id, String name) => _repo.rename(id, name);

  Future<void> saveManual(String name, String address) => _repo.saveManual(name, address);

  /// Throws if the write fails: the caller says so.
  Future<void> reorder(List<String> ids) => _repo.reorder(ids);
}

final radioOpsProvider = Provider<RadioOps>(RadioOps.new);
