import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_log.dart';
import '../../../core/constants.dart';
import '../../../core/platform.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../services/import/exportify_reader.dart';
import '../../theme/tokens.dart';

const exportifyAddress = 'https://exportify.net';

/// Explains where the CSV comes from (exportify.net) and lets the user pick it.
/// Pops with the parsed playlist.
class ImportIntroSheet extends StatefulWidget {
  const ImportIntroSheet({super.key});

  static Future<ExportifyPlaylist?> show(BuildContext context) =>
      showModalBottomSheet<ExportifyPlaylist>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (_) => const ImportIntroSheet(),
      );

  @override
  State<ImportIntroSheet> createState() => _ImportIntroSheetState();
}

class _ImportIntroSheetState extends State<ImportIntroSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      // Some Android file pickers hide .csv behind a MIME filter, so there
      // the whole list is shown and the content is validated instead.
      final files = await FilePicker.pickFiles(
        type: isAndroid ? FileType.any : FileType.custom,
        allowedExtensions: isAndroid ? null : const ['csv'],
      );
      final path = files.isEmpty ? null : files.first.path;
      if (path == null) {
        if (files.isNotEmpty) error = l.csvImportReadFailed;
      } else {
        final text = utf8.decode(
          await File(path).readAsBytes(),
          allowMalformed: true,
        );
        final csv = await readExportifyInIsolate(files.first.name, text);
        if (!mounted) return;
        Navigator.of(context).pop(csv);
        return;
      }
    } on FormatException catch (e, st) {
      AppLog.w('not an Exportify file', e, st);
      error = l.csvImportNotExportify;
    } on Object catch (e, st) {
      AppLog.w('could not read the CSV', e, st);
      error = l.csvImportReadFailed;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final text = context.l10n.csvImportCopied;
    await Clipboard.setData(const ClipboardData(text: exportifyAddress));
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final steps = [
      l.csvImportStep1,
      l.csvImportStep2,
      l.csvImportStep3,
      l.csvImportStep4,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CcDims.margin,
          8,
          CcDims.margin,
          CcDims.margin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.csvImportIntroTitle, style: theme.titleLarge),
            const SizedBox(height: 8),
            Text(l.csvImportIntroSource, style: theme.bodyMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}.',
                        style: theme.bodyMedium?.copyWith(color: cc.accent),
                      ),
                    ),
                    Expanded(child: Text(steps[i], style: theme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: SelectableText(
                    exportifyAddress,
                    maxLines: 1,
                  ),
                ),
                TextButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(l.csvImportCopy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              kEnableYoutube ? l.csvImportNote : l.csvImportNoteOffline,
              style: theme.bodySmall?.copyWith(color: cc.textMuted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.bodyMedium?.copyWith(color: cc.error),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _busy ? null : _pick,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(l.csvImportPick),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
