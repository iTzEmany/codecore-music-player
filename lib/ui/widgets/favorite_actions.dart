import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_providers.dart';
import 'confirm.dart';

/// Toggles the favourite flag and shows a single "Undo" snackbar that
/// restores the state of the last change.
Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final repo = ref.read(trackRepositoryProvider);
  final fresh = await repo.getById(track.id);
  if (fresh == null) return;
  final previous = fresh.isFavorite;
  await repo.setFavorite(track.id, !previous);
  if (!context.mounted) return;
  if (!ref.read(settingsProvider).showUndoSnackbar) return;
  final l = context.l10n;
  showUndoSnack(
    context,
    previous ? l.removedFromFavorites : l.addedToFavorites,
    () => repo.setFavorite(track.id, previous),
  );
}
