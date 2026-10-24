import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/platform.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/memory_queries.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../../services/library/duplicate_finder.dart';
import '../../theme/app_theme.dart' show ccIconDensity;
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/track_actions.dart' show revealInFolder;
import '../memory/folder_labels.dart';
import '../../widgets/show_msg.dart';

/// «Music › Pink Floyd › The Wall»: the folder of [path] relative to the
/// library root that contains it, the root named like Memoria names it. With
/// no matching root the whole absolute folder is shown.
String dupFolderLabel(String path, List<Folder> roots) {
  final dir = p.dirname(path);
  Folder? root;
  for (final r in roots) {
    final inside = p.equals(r.path, dir) || p.isWithin(r.path, dir);
    if (inside && (root == null || r.path.length > root.path.length)) root = r;
  }
  if (root == null) return dir;
  final labels = folderLabels([
    for (final r in roots)
      SizeGroup(
        name: r.label ?? p.basename(r.path),
        path: r.path,
        totals: const SizeTotals(),
      ),
  ]);
  final head = labels[root.path] ?? p.basename(root.path);
  final rest = p.split(p.relative(dir, from: root.path))
    ..removeWhere((s) => s == '.' || s.isEmpty);
  return [head, ...rest].join(' › ');
}

/// One copy in a duplicate group: full file name, folder, details; a long
/// press (or the info button) opens the absolute path.
class DuplicateMemberRow extends ConsumerWidget {
  const DuplicateMemberRow({
    super.key,
    required this.entry,
    required this.keep,
    required this.onTap,
  });

  final DupEntry entry;
  final bool keep;
  final VoidCallback onTap;

  String _meta(BuildContext context, DupEntry e) => [
    e.format.toUpperCase(),
    if (e.bitrateKbps != null) '${e.bitrateKbps} kbps',
    if (e.bitDepth != null) '${e.bitDepth} bit',
    if (e.sampleRateHz != null) '${(e.sampleRateHz! / 1000).toStringAsFixed(1)} kHz',
    formatBytes(e.sizeBytes, Localizations.localeOf(context).toString()),
    formatDuration(e.durationMs),
  ].join(', ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final roots = ref.watch(foldersProvider).value ?? const <Folder>[];
    final muted = theme.labelSmall?.copyWith(color: cc.textMuted);
    return Semantics(
      selected: keep,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        key: ValueKey('dup-member-${entry.id}'),
        onTap: onTap,
        onLongPress: () => showDupPathDialog(context, entry.path),
        child: Container(
          color: keep ? cc.accentSoft.withValues(alpha: 0.14) : null,
          padding: const EdgeInsets.fromLTRB(CcDims.gap16, CcDims.gap8, CcDims.gap4, CcDims.gap8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  keep
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: keep ? cc.accent : cc.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.basename(entry.path),
                      key: ValueKey('dup-name-${entry.id}'),
                      style: theme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dupFolderLabel(entry.path, roots),
                      key: ValueKey('dup-folder-${entry.id}'),
                      style: theme.bodySmall?.copyWith(color: cc.textMuted),
                    ),
                    Text(_meta(context, entry), style: muted),
                    if (keep)
                      Text(
                        l.duplicatesKeepLabel,
                        style: theme.labelSmall?.copyWith(color: cc.accent),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('dup-info-${entry.id}'),
                tooltip: l.details,
                visualDensity: ccIconDensity,
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                onPressed: () => showDupPathDialog(context, entry.path),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showDupPathDialog(BuildContext context, String path) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.details),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.detailPath, style: Theme.of(ctx).textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(path, key: const ValueKey('dup-full-path')),
          ],
        ),
      ),
      actions: [
        if (isDesktop)
          TextButton(
            onPressed: () => revealInFolder(path),
            child: Text(l.showInFolder),
          ),
        TextButton(
          key: const ValueKey('dup-copy-path'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: path));
            if (!ctx.mounted) return;
            showMsg(context, l.copied);
          },
          child: Text(l.copy),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
      ],
    ),
  );
}
