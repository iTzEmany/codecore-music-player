import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/library/duplicate_finder.dart';
import '../../theme/tokens.dart';
import '../../widgets/format_utils.dart';

/// One group of duplicates: its tracks with path, quality and size, the one
/// proposed to keep highlighted (a tap picks another), and the two ways out.
class DuplicateGroupCard extends StatefulWidget {
  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.onMerge,
    required this.onNotDuplicates,
  });

  final DuplicateGroup group;
  final void Function(int keepId) onMerge;
  final VoidCallback onNotDuplicates;

  @override
  State<DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends State<DuplicateGroupCard> {
  late int _keepId = widget.group.proposed.id;

  @override
  void didUpdateWidget(DuplicateGroupCard old) {
    super.didUpdateWidget(old);
    if (old.group.key != widget.group.key) _keepId = widget.group.proposed.id;
  }

  String _meta(DupEntry e) => [
    e.format.toUpperCase(),
    if (e.bitrateKbps != null) '${e.bitrateKbps} kbps',
    formatBytes(e.sizeBytes),
    formatDuration(e.durationMs),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final g = widget.group;
    final first = g.proposed;
    return Card(
      key: ValueKey('dup-${g.key}'),
      margin: const EdgeInsets.symmetric(
        horizontal: CcDims.margin,
        vertical: 6,
      ),
      color: cc.surface1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleMedium,
                        ),
                        if ((first.artist ?? '').isNotEmpty)
                          Text(
                            first.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      g.exact
                          ? l.duplicatesExactBadge
                          : l.duplicatesProbableBadge,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                l.duplicatesPickKeep,
                style: theme.labelSmall?.copyWith(color: cc.textMuted),
              ),
            ),
            for (final m in g.members) _memberRow(context, m),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: widget.onNotDuplicates,
                    child: Text(l.duplicatesNotDuplicates),
                  ),
                  FilledButton(
                    onPressed: () => widget.onMerge(_keepId),
                    child: Text(l.duplicatesMerge),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberRow(BuildContext context, DupEntry m) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final keep = m.id == _keepId;
    return Semantics(
      selected: keep,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        key: ValueKey('dup-member-${m.id}'),
        onTap: () => setState(() => _keepId = m.id),
        child: Container(
          color: keep ? cc.accentSoft.withValues(alpha: 0.14) : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                keep
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: keep ? cc.accent : cc.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium,
                    ),
                    Text(
                      _meta(m),
                      style: theme.labelSmall?.copyWith(color: cc.textMuted),
                    ),
                  ],
                ),
              ),
              if (keep)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    l.duplicatesKeepLabel,
                    style: theme.labelSmall?.copyWith(color: cc.accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
