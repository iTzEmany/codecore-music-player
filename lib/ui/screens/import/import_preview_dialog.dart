import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../services/import/exportify_reader.dart';
import '../../../services/import/import_diff.dart' show ImportDiff;
import '../../../services/import/import_options.dart';
import '../../theme/tokens.dart';

/// Above this many songs to download the preview suggests splitting the import.
const bigImportRows = 200;
const importBlockSize = 100;

class ImportChoice {
  const ImportChoice(this.name, this.intoPlaylistId,
      [this.options = const ImportOptions(), this.blockSize, this.sync = false]);

  /// Make the existing playlist follow the file (adds and removes).
  final bool sync;

  final String name;
  final ImportOptions options;

  /// Rows per import when a big file is split; null = a single import.
  final int? blockSize;

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
    this.syncPreview,
  });

  /// What a sync of the file into an existing playlist would change; without
  /// it the «Sincronizza» choice is not offered.
  final Future<ImportDiff> Function(int playlistId)? syncPreview;

  final ImportedPlaylist csv;
  final int known;
  final Map<int, String> existing;

  @override
  State<ImportPreviewDialog> createState() => _State();
}

enum _Existing { addNew, sync, create }

class _State extends State<ImportPreviewDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.csv.name,
  );
  _Existing _existing = _Existing.addNew;
  Future<ImportDiff>? _diff;
  int? _diffOf;

  /// One query per playlist, not one per rebuild.
  Future<ImportDiff> _diffFor(int playlistId) {
    if (_diffOf != playlistId) {
      _diffOf = playlistId;
      _diff = widget.syncPreview!(playlistId);
    }
    return _diff!;
  }
  bool _linkOnly = false;
  late bool _blocks = (widget.csv.rows.length - widget.known) > bigImportRows;
  bool _planFirst = false;
  bool _ownFolder = false;
  bool _numberFiles = false;
  bool _fetchCovers = false;

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
                  !kEnableYoutube
                      ? l.csvImportNoteOffline
                      : minutes >= 60
                      ? l.csvImportEstimateHours(minutes ~/ 60, minutes % 60)
                      : l.csvImportEstimate(minutes < 1 ? 1 : minutes),
                  style: theme.bodySmall?.copyWith(color: cc.textMuted),
                ),
              ),
            if (kEnableYoutube && todo > bigImportRows && !_linkOnly)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.csvImportBlocks(importBlockSize)),
                subtitle: Text(l.csvImportBigWarning(todo)),
                value: _blocks,
                onChanged: (v) => setState(() => _blocks = v ?? false),
              ),
            if (kEnableYoutube && todo > 0) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.csvImportLinkOnly),
                subtitle: Text(l.csvImportLinkOnlyHint),
                value: _linkOnly,
                onChanged: (v) => setState(() => _linkOnly = v),
              ),
              if (!_linkOnly) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.csvImportPlanFirst),
                  subtitle: Text(l.csvImportPlanFirstHint),
                  value: _planFirst,
                  onChanged: (v) => setState(() => _planFirst = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.csvImportOwnFolder),
                  subtitle: Text(l.csvImportOwnFolderHint),
                  value: _ownFolder,
                  onChanged: (v) => setState(() => _ownFolder = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.csvImportFetchCovers),
                  subtitle: Text(l.csvImportFetchCoversHint),
                  value: _fetchCovers,
                  onChanged: (v) => setState(() => _fetchCovers = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.csvImportNumberFiles),
                  subtitle: Text(l.csvImportNumberFilesHint),
                  value: _numberFiles,
                  onChanged: (v) => setState(() => _numberFiles = v),
                ),
              ],
            ],
            if (same != null) ...[
              const SizedBox(height: 16),
              Text(l.csvImportExists, style: theme.titleSmall),
              RadioGroup<_Existing>(
                groupValue: _existing,
                onChanged: (v) =>
                    setState(() => _existing = v ?? _Existing.addNew),
                child: Column(
                  children: [
                    RadioListTile<_Existing>(
                      contentPadding: EdgeInsets.zero,
                      value: _Existing.addNew,
                      title: Text(l.csvImportUpdate),
                    ),
                    if (widget.syncPreview != null)
                      RadioListTile<_Existing>(
                        contentPadding: EdgeInsets.zero,
                        value: _Existing.sync,
                        title: Text(l.csvImportSync),
                        subtitle: FutureBuilder<ImportDiff>(
                          key: ValueKey(same),
                          future: _diffFor(same),
                          builder: (context, snap) => Text(snap.hasData
                              ? l.csvImportSyncCounts(
                                  snap.data!.added.length, snap.data!.removed.length)
                              : l.csvImportSyncChecking),
                        ),
                      ),
                    RadioListTile<_Existing>(
                      contentPadding: EdgeInsets.zero,
                      value: _Existing.create,
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
                    same != null && _existing != _Existing.create ? same : null,
                    ImportOptions(
                      linkOnly: _linkOnly,
                      planFirst: _planFirst && !_linkOnly,
                      folderPath: _ownFolder && !_linkOnly
                          ? _name.text.trim()
                          : null,
                      numberFiles: _numberFiles && !_linkOnly,
                      fetchCovers: _fetchCovers && !_linkOnly,
                    ),
                    todo > bigImportRows && _blocks && !_linkOnly
                        ? importBlockSize
                        : null,
                    same != null && _existing == _Existing.sync,
                  ),
                ),
          child: Text(l.csvImportGo),
        ),
      ],
    );
  }
}
