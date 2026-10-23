import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/playlist_repository.dart'
    show PlaylistSummary;
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/import_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/import/exportify_zip.dart';
import '../../../services/import/imported_playlist.dart';
import '../../../services/import/import_chain.dart';
import '../../../services/import/import_diff.dart' show ImportDiff;
import '../../../services/import/import_options.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_header.dart';

class _Entry {
  _Entry(this.csv);

  final ImportedPlaylist csv;

  /// Playlist it syncs into; null = new (or still to choose when [ambiguous]).
  int? playlistId;
  bool ambiguous = false;
  ImportDiff? diff;
  bool selected = false;
  bool failed = false;

  int get changes => (diff?.added.length ?? 0) + (diff?.removed.length ?? 0);
}

/// «Sincronizza da Spotify»: one preview for every playlist of an Exportify
/// «Export All» ZIP. Ticked entries are synced one after the other.
class ExportifySyncScreen extends ConsumerStatefulWidget {
  const ExportifySyncScreen({super.key, required this.zip});

  final ExportifyZipResult zip;

  @override
  ConsumerState<ExportifySyncScreen> createState() =>
      _ExportifySyncScreenState();
}

class _ExportifySyncScreenState extends ConsumerState<ExportifySyncScreen> {
  List<_Entry>? _entries;
  List<PlaylistSummary>? _lists;

  /// Options of each playlist's latest import, used again by the sync.
  final _lastImport = <int, PlaylistImport>{};
  bool _busy = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loadFailed) setState(() => _loadFailed = false);
    try {
      final lists = await ref.read(playlistsProvider.future);
      final repo = ref.read(importRepositoryProvider);
      for (final p in lists) {
        final all = await repo.forPlaylist(p.playlist.id);
        if (all.isNotEmpty) {
          _lastImport[p.playlist.id] = all.reduce(
            (a, b) => a.id > b.id ? a : b,
          );
        }
      }
      final matches = matchExportifyEntries(
        [for (final e in widget.zip.entries) e.fileName],
        [
          for (final p in lists)
            (
              id: p.playlist.id,
              name: p.playlist.name,
              lastImportName: _lastImport[p.playlist.id] == null
                  ? null
                  : importLabel(_lastImport[p.playlist.id]!.sourceName),
            ),
        ],
      );
      final entries = <_Entry>[];
      for (var i = 0; i < matches.length; i++) {
        final e = _Entry(widget.zip.entries[i].playlist)
          ..playlistId = matches[i].playlistId
          ..ambiguous = matches[i].ambiguous;
        if (e.playlistId != null) await _preview(e);
        entries.add(e);
      }
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _entries = entries;
      });
    } on Object catch (e, st) {
      AppLog.w('Exportify sync preview failed', e, st);
      if (!mounted) return;
      setState(() {
        _lists = const [];
        _loadFailed = true;
      });
    }
  }

  /// Fills [e]'s diff; on failure the entry is marked failed and unticked.
  Future<void> _preview(_Entry e) async {
    try {
      e.diff = await ref
          .read(playlistImportServiceProvider)
          .previewSync(e.csv, e.playlistId!);
      e.failed = false;
      e.selected = e.changes > 0;
    } on Object catch (err, st) {
      AppLog.w('Exportify preview of ${e.csv.name} failed', err, st);
      e.diff = null;
      e.failed = true;
      e.selected = false;
    }
  }

  Future<void> _choose(_Entry e) async {
    final l = context.l10n;
    final lists = _lists ?? const <PlaylistSummary>[];
    // -1 = new playlist.
    final id = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(l.exportifySyncPickTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, -1),
            child: Text(l.exportifySyncNew),
          ),
          for (final p in lists)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, p.playlist.id),
              child: Text(p.playlist.name),
            ),
        ],
      ),
    );
    if (id == null || !mounted) return;
    e.ambiguous = false;
    e.playlistId = id < 0 ? null : id;
    e.diff = null;
    e.failed = false;
    e.selected = false;
    if (id >= 0) await _preview(e);
    if (mounted) setState(() {});
  }

  Future<void> _run(List<_Entry> chosen) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final svc = ref.read(playlistImportServiceProvider);
    final store = ref.read(settingsStoreProvider);
    final done = context.l10n.exportifySyncDone;
    final failedText = context.l10n.exportifySyncFailed;
    setState(() => _busy = true);
    var ok = 0;
    for (final e in chosen) {
      try {
        final id = e.playlistId;
        final last = id == null ? null : _lastImport[id];
        final options = last == null
            ? const ImportOptions()
            : ImportOptions(
                folderPath: last.folderPath,
                numberFiles: last.numberFiles,
                linkOnly: last.linkOnly,
                fetchCovers: last.fetchCovers,
              );
        if (id == null) {
          await svc.start(e.csv, name: e.csv.name);
        } else {
          await svc.sync(e.csv, id, options: options);
        }
        ok++;
      } on Object catch (err, st) {
        AppLog.w('Exportify sync of ${e.csv.name} failed', err, st);
      }
    }
    if (ok > 0) {
      await store.writeExportifyLastSyncAt(
        DateTime.now().millisecondsSinceEpoch,
      );
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(ok > 0 ? done(ok) : failedText)));
    if (!mounted) return;
    if (ok > 0) {
      nav.pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    // Keeps the playlists stream listened to while _load waits for it.
    ref.watch(playlistsProvider);
    final entries = _entries;
    final names = {
      for (final p in _lists ?? const <PlaylistSummary>[])
        p.playlist.id: p.playlist.name,
    };
    final active = [
      for (final e in entries ?? const <_Entry>[])
        if (e.ambiguous || e.failed || e.playlistId == null || e.changes > 0) e,
    ];
    final quiet = [
      for (final e in entries ?? const <_Entry>[])
        if (!active.contains(e)) e,
    ];
    final chosen = [
      for (final e in entries ?? const <_Entry>[])
        if (e.selected) e,
    ];

    Widget tile(_Entry e) {
      final String sub;
      if (e.failed) {
        sub = l.exportifySyncEntryFailed;
      } else if (e.ambiguous) {
        sub = l.exportifySyncChoose;
      } else if (e.playlistId == null) {
        sub = l.exportifySyncNew;
      } else {
        sub =
            '${names[e.playlistId] ?? ''}, '
            '${e.changes == 0 ? l.exportifySyncNoChanges : l.exportifySyncChanges(e.diff!.added.length, e.diff!.removed.length)}';
      }
      return CheckboxListTile(
        value: e.selected,
        onChanged: e.ambiguous || e.failed || _busy
            ? null
            : (v) => setState(() => e.selected = v ?? false),
        title: Text(e.csv.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          sub,
          style: TextStyle(
            color: e.failed
                ? cc.error
                : e.ambiguous
                ? cc.accent
                : cc.textMuted,
          ),
        ),
        secondary: e.ambiguous
            ? TextButton(
                onPressed: _busy ? null : () => _choose(e),
                child: Text(l.exportifySyncChoose),
              )
            : null,
      );
    }

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.exportifySyncTitle)),
        body: _loadFailed
            ? ErrorState(message: l.exportifySyncLoadFailed, onRetry: _load)
            : entries == null
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
            ? EmptyState(
                icon: Icons.sync_rounded,
                message: l.exportifySyncEmpty,
                help: widget.zip.skipped > 0
                    ? l.exportifySyncSkipped(widget.zip.skipped)
                    : null,
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: ListView(
                    children: [
                      for (final e in active) tile(e),
                      if (quiet.isNotEmpty)
                        SectionHeader(l.exportifySyncNoChanges),
                      for (final e in quiet) tile(e),
                      if (widget.zip.skipped > 0)
                        Padding(
                          padding: const EdgeInsets.all(CcDims.margin),
                          child: Text(
                            l.exportifySyncSkipped(widget.zip.skipped),
                            style: theme.bodySmall?.copyWith(
                              color: cc.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: chosen.isEmpty && !_busy
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(CcDims.margin),
                  child: FilledButton(
                    onPressed: _busy ? null : () => _run(chosen),
                    child: Text(
                      l.exportifySyncGo(chosen.length),
                      style: theme.labelLarge,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
