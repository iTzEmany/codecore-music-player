import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../services/import/exportify_reader.dart';
import '../../theme/tokens.dart';

class ImportChoice {
  const ImportChoice(this.name, this.intoPlaylistId);

  final String name;

  /// Existing playlist to update; null = create a new one.
  final int? intoPlaylistId;
}

/// Shows what the import will do before anything starts. [known] is how many
/// rows the library already has; [existing] maps playlist ids to names.
class ImportPreviewDialog extends StatefulWidget {
  const ImportPreviewDialog({
    super.key,
    required this.csv,
    required this.known,
    required this.existing,
  });

  final ImportedPlaylist csv;
  final int known;
  final Map<int, String> existing;

  @override
  State<ImportPreviewDialog> createState() => _State();
}

class _State extends State<ImportPreviewDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.csv.name,
  );
  bool _update = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int? _sameName() {
    final n = _name.text.trim().toLowerCase();
    if (n.isEmpty) return null;
    for (final e in widget.existing.entries) {
      if (e.value.trim().toLowerCase() == n) return e.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final total = widget.csv.rows.length;
    final todo = total - widget.known;
    final same = _sameName();
    final minutes = (todo * 12 / 60).ceil();
    return AlertDialog(
      title: Text(l.csvImportPreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.csvImportName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              l.csvImportSummary(total, widget.known, todo),
              style: theme.bodyLarge,
            ),
            if (widget.csv.skipped > 0)
              Text(
                l.csvImportSkipped(widget.csv.skipped),
                style: theme.bodySmall?.copyWith(color: cc.textMuted),
              ),
            if (todo > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  kEnableYoutube
                      ? l.csvImportEstimate(minutes < 1 ? 1 : minutes)
                      : l.csvImportNoteOffline,
                  style: theme.bodySmall?.copyWith(color: cc.textMuted),
                ),
              ),
            if (same != null) ...[
              const SizedBox(height: 16),
              Text(l.csvImportExists, style: theme.titleSmall),
              RadioGroup<bool>(
                groupValue: _update,
                onChanged: (v) => setState(() => _update = v ?? true),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: true,
                      title: Text(l.csvImportUpdate),
                    ),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: false,
                      title: Text(l.csvImportNew),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty || total == 0
              ? null
              : () => Navigator.pop(
                  context,
                  ImportChoice(
                    _name.text.trim(),
                    same != null && _update ? same : null,
                  ),
                ),
          child: Text(l.csvImportGo),
        ),
      ],
    );
  }
}
