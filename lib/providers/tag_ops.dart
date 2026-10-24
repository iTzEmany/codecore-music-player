import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/tag_repository.dart';
import 'database_providers.dart';

/// Tag actions on tags and on the tracks that carry them.
class TagOps {
  TagOps(this._ref);

  final Ref _ref;

  TagRepository get _repo => _ref.read(tagRepositoryProvider);

  /// Creates the tag and gives it to [assignTo]; null if it did not come out
  /// as the row just made.
  Future<UserTag?> create(String name, {List<int> assignTo = const []}) async {
    final id = await _repo.create(name);
    if (assignTo.isNotEmpty) await _repo.assign(assignTo, id);
    return _byId(id, name);
  }

  Future<UserTag?> _byId(int id, String name) async {
    final tag = await _repo.byName(name);
    return tag != null && tag.id == id ? tag : null;
  }

  /// False when another tag already has that name.
  Future<bool> rename(int id, String name) => _repo.rename(id, name);
  Future<void> setColor(int id, int? color) => _repo.setColor(id, color);
  Future<void> delete(int id) => _repo.delete(id);

  /// How many of [trackIds] carry each tag (only tags carried by some).
  Future<Map<int, int>> countsAmong(List<int> trackIds) => _repo.countsAmong(trackIds);

  /// Gives or takes a tag; returns how many tracks changed.
  Future<int> assign(List<int> trackIds, int tagId) => _repo.assign(trackIds, tagId);
  Future<int> unassign(List<int> trackIds, int tagId) => _repo.unassign(trackIds, tagId);

  Future<List<TagSummary>> all() => _repo.watchAll().first;
}

final tagOpsProvider = Provider<TagOps>(TagOps.new);
