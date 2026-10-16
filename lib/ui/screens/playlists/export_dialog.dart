import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../data/db/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../services/export/playlist_exporter.dart';
import '../../../services/export/save_file.dart';

class _ExportChoice {
  const _ExportChoice(this.format, this.relative);

  final ExportFormat format;
  final bool relative;
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _format = ExportFormat.m3u8;
  bool _relative = false;

  String _label(AppLocalizations l, ExportFormat f) => switch (f) {
        ExportFormat.m3u8 => l.exportFormatM3u8,
        ExportFormat.csv => l.exportFormatCsv,
        ExportFormat.json => l.exportFormatJson,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.exportPlaylistTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<ExportFormat>(
              groupValue: _format,
              onChanged: (v) => setState(() => _format = v ?? _format),
              child: Column(children: [
                for (final f in ExportFormat.values)
                  RadioListTile<ExportFormat>(
                    value: f,
                    title: Text(_label(l, f)),
                  ),
              ]),
            ),
            if (_format == ExportFormat.m3u8)
              CheckboxListTile(
                value: _relative,
                onChanged: (v) => setState(() => _relative = v ?? false),
                title: Text(l.exportRelativePaths),
                subtitle: Text(l.exportRelativeHint),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _ExportChoice(_format, _relative)),
          child: Text(l.exportAction),
        ),
      ],
    );
  }
}

/// Asks for the format, then saves the playlist where the user chooses.
Future<void> exportPlaylistFlow(
  BuildContext context,
  WidgetRef ref, {
  required Playlist playlist,
  required String name,
  required List<Track> tracks,
}) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  if (tracks.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l.exportEmpty)));
    return;
  }
  final choice = await showDialog<_ExportChoice>(
      context: context, builder: (_) => const ExportDialog());
  if (choice == null) return;
  try {
    final db = ref.read(databaseProvider);
    final text = renderPlaylist(
      choice.format,
      name: name,
      createdAt: playlist.createdAt,
      coverKey: playlist.coverKey,
      tracks: tracks,
      isrcByTrack:
          await ref.read(importRepositoryProvider).isrcByTrack(playlist.id),
      folders: {
        for (final f in await db.select(db.folders).get()) f.id: f.path,
      },
      relativePaths: choice.relative,
    );
    final saved = await saveBytes(
        exportFileName(name, choice.format), utf8.encode(text),
        mimeType: choice.format.mimeType);
    if (saved) messenger.showSnackBar(SnackBar(content: Text(l.exportSaved)));
  } on Object catch (e, st) {
    AppLog.e('export playlist failed', e, st);
    messenger.showSnackBar(SnackBar(content: Text(l.exportFailed)));
  }
}
