import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/tag_repository.dart';
import '../services/library/rules/rule_ast.dart';
import 'database_providers.dart';

final tagsProvider = StreamProvider<List<TagSummary>>(
  (ref) => ref.watch(tagRepositoryProvider).watchAll(),
);

/// The tracks that carry the tag named [name] (the rule `tag:name`).
final tagTracksProvider = StreamProvider.family<List<Track>, String>(
  (ref, name) => ref
      .watch(trackRepositoryProvider)
      .watchByRules(RuleContains(RuleField.tag, name)),
);
