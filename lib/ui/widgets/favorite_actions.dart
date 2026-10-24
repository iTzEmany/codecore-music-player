import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/track_ops.dart';
import '../../providers/settings_providers.dart';
import 'confirm.dart';

/// Toggles the favourite flag and shows a single "Undo" snackbar that
/// restores the state of the last change.
Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final r = await ref.read(trackOpsProvider).toggleFavorite(track.id);
  if (r == null) return;
  if (!context.mounted) return;
  if (!ref.read(settingsProvider).showUndoSnackbar) return;
  final l = context.l10n;
  showUndoSnack(
    context,
    r.added ? l.addedToFavorites : l.removedFromFavorites,
    r.undo,
  );
}
