import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/library/duplicate_finder.dart';
import '../../theme/tokens.dart';
import 'duplicate_member_row.dart';

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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final g = widget.group;
    final first = g.proposed;
    return Padding(
      key: ValueKey('dup-${g.key}'),
      padding: const EdgeInsets.symmetric(
        horizontal: CcDims.margin,
        vertical: 6,
      ),
      child: Material(
        color: cc.surface1,
        borderRadius: BorderRadius.circular(CcDims.rCard),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CcDims.gap8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CcDims.gap16),
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
                    Text(
                      g.exact
                          ? l.duplicatesExactBadge
                          : l.duplicatesProbableBadge,
                      style: theme.labelMedium?.copyWith(
                        color: g.exact ? cc.accent : cc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(CcDims.gap16, CcDims.gap4, CcDims.gap16, CcDims.gap4),
                child: Text(
                  l.duplicatesPickKeep,
                  style: theme.labelSmall?.copyWith(color: cc.textMuted),
                ),
              ),
              for (final m in g.members)
                DuplicateMemberRow(
                  entry: m,
                  keep: m.id == _keepId,
                  onTap: () => setState(() => _keepId = m.id),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(CcDims.gap8, CcDims.gap4, CcDims.gap8, 0),
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
      ),
    );
  }
}
