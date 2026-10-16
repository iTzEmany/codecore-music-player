import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/import_providers.dart';
import '../../../services/import/track_matcher.dart';
import 'import_intro_sheet.dart';
import 'import_preview_dialog.dart';

/// «Importa da Exportify (CSV)»: instructions + file → preview → start.
Future<void> startCsvImport(BuildContext context, WidgetRef ref) async {
  final csv = await ImportIntroSheet.show(context);
  if (csv == null || !context.mounted) return;
  final library = LibraryIndex(
    await ref.read(trackRepositoryProvider).liteEntries(),
  );
  final known = csv.rows.where((r) => library.find(r) != null).length;
  final lists = await ref.read(playlistsProvider.future);
  if (!context.mounted) return;
  final choice = await showDialog<ImportChoice>(
    context: context,
    builder: (_) => ImportPreviewDialog(
      csv: csv,
      known: known,
      existing: {for (final p in lists) p.playlist.id: p.playlist.name},
    ),
  );
  if (choice == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final started = context.l10n.csvImportStarted;
  await ref
      .read(playlistImportServiceProvider)
      .start(csv, name: choice.name, intoPlaylistId: choice.intoPlaylistId);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(started)));
}
