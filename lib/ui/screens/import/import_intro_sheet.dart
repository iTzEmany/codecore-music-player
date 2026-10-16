import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/app_log.dart';
import '../../../core/constants.dart';
import '../../../core/platform.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../services/import/exportify_reader.dart' show CsvTooLargeException, checkCsvSize;
import '../../../services/import/imported_playlist.dart';
import '../../../services/import/playlist_reader.dart';
import '../../theme/tokens.dart';

const exportifyAddress = 'https://exportify.net';

/// Explains where the CSV comes from (exportify.net) and lets the user pick it.
/// Pops with the parsed playlist.
class ImportIntroSheet extends StatefulWidget {
  const ImportIntroSheet({super.key});

  static Future<ImportedPlaylist?> show(BuildContext context) =>
      showModalBottomSheet<ImportedPlaylist>(
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

  /// Desktop pickers open in Downloads, where the browser leaves the CSV.
  Future<String?> _startDir() async {
    if (!isDesktop) return null;
    try {
      return (await getDownloadsDirectory())?.path;
    } on Object catch (e, st) {
      AppLog.w('downloads folder unknown', e, st);
      return null;
    }
  }

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
        dialogTitle: l.csvImportPick,
        initialDirectory: await _startDir(),
        type: isAndroid ? FileType.any : FileType.custom,
        allowedExtensions: isAndroid ? null : supportedPlaylistExtensions,
      );
      final path = files.isEmpty ? null : files.first.path;
      if (path == null) {
        if (files.isNotEmpty) error = l.csvImportReadFailed;
      } else {
        checkCsvSize(await File(path).length());
        final text = decodePlaylistBytes(
          files.first.name,
          await File(path).readAsBytes(),
        );
        final csv = await readPlaylistFileInIsolate(files.first.name, text);
        if (!mounted) return;
        Navigator.of(context).pop(csv);
        return;
      }
    } on CsvTooLargeException catch (e, st) {
      AppLog.w('CSV too large', e, st);
      error = l.csvImportTooBig;
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
            Text(l.csvImportAlsoAccepts,
                style: theme.bodySmall?.copyWith(color: cc.textMuted)),
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
