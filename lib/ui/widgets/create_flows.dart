import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/playlist_ops.dart';
import '../../providers/tag_ops.dart';
import 'prompt_name.dart';

/// «New playlist»: asks the name and creates it. Null when cancelled.
Future<({int id, String name})?> createPlaylistFlow(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final name = await promptName(context, title: l.newPlaylist, confirmLabel: l.create, hint: l.playlistName);
  if (name == null || !context.mounted) return null;
  return (id: await ref.read(playlistOpsProvider).create(name), name: name);
}

/// «New tag» (max 40): asks the name and creates it, giving it to [assignTo] too.
/// Null when cancelled, or when the row read back is not the one just made.
Future<UserTag?> createTagFlow(BuildContext context, WidgetRef ref, {List<int> assignTo = const []}) async {
  final l = context.l10n;
  final name = await promptName(context, title: l.tagNew, confirmLabel: l.save, maxLength: 40);
  if (name == null || !context.mounted) return null;
  final ops = ref.read(tagOpsProvider);
  return assignTo.isEmpty ? ops.createNamed(name) : ops.createAndAssign(name, assignTo);
}
