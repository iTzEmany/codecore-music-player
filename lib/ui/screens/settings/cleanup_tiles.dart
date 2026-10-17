import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/duplicate_providers.dart';
import '../cleanup/duplicates_screen.dart';
import '../cleanup/hidden_tracks_screen.dart';

/// The «Pulizia libreria» entries of Settings: duplicates and hidden tracks.
List<Widget> cleanupTiles(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final hidden = ref.watch(hiddenTracksProvider).value?.length ?? 0;
  void open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));
  return [
    ListTile(
      leading: const Icon(Icons.content_copy_rounded),
      title: Text(l.duplicatesTitle),
      subtitle: Text(l.duplicatesTileHint),
      onTap: () => open(const DuplicatesScreen()),
    ),
    ListTile(
      leading: const Icon(Icons.visibility_off_outlined),
      title: Text(
        hidden == 0 ? l.hiddenTracksTitle : l.hiddenTracksCount(hidden),
      ),
      onTap: () => open(const HiddenTracksScreen()),
    ),
  ];
}
