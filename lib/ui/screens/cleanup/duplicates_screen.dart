import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/duplicate_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/confirm.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_utils.dart';
import 'delete_files_dialogs.dart';
import 'duplicate_group_card.dart';

/// Settings → Library cleanup → Duplicates: search, preview of every group,
/// merge one by one or all the identical ones, and (optionally) delete files.
class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _mergeAll(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final exact = [
      for (final g in ref.read(duplicateSearchProvider).groups)
        if (g.exact) g,
    ];
    final hidden = exact.fold<int>(0, (n, g) => n + g.members.length - 1);
    final ok = await showConfirm(
      context,
      title: l.duplicatesMergeAllTitle,
      body: l.duplicatesMergeAllBody(exact.length, hidden),
      confirmLabel: l.duplicatesMerge,
    );
    if (!ok) return;
    await ref.read(duplicateSearchProvider.notifier).mergeAllExact();
    if (context.mounted) _snack(context, l.duplicatesMerged(hidden));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(duplicateSearchProvider);
    final notifier = ref.read(duplicateSearchProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.duplicatesTitle),
        actions: [
          if (s.phase == DuplicatePhase.done && s.groups.isNotEmpty)
            IconButton(
              tooltip: l.duplicatesSearchAgain,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: notifier.start,
            ),
        ],
      ),
      body: switch (s.phase) {
        DuplicatePhase.idle => _Intro(onSearch: notifier.start),
        DuplicatePhase.reading ||
        DuplicatePhase.hashing ||
        DuplicatePhase.grouping => _Progress(
          state: s,
          onCancel: notifier.cancel,
        ),
        DuplicatePhase.failed => EmptyState(
          icon: Icons.error_outline_rounded,
          message: l.duplicatesFailed,
          actionLabel: l.retry,
          onAction: notifier.start,
        ),
        DuplicatePhase.done => _Results(
          state: s,
          onMergeAll: () => _mergeAll(context, ref),
        ),
      },
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.duplicatesIntro,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                label: Text(l.duplicatesSearch),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state, required this.onCancel});

  final DuplicateSearchState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = switch (state.phase) {
      DuplicatePhase.reading => l.duplicatesReading,
      DuplicatePhase.hashing => l.duplicatesHashing(state.done, state.total),
      _ => l.duplicatesGrouping,
    };
    final value = state.phase == DuplicatePhase.hashing && state.total > 0
        ? state.done / state.total
        : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            SizedBox(
              width: 320,
              child: LinearProgressIndicator(value: value),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onCancel, child: Text(l.cancel)),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.state, required this.onMergeAll});

  final DuplicateSearchState state;
  final VoidCallback onMergeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final notifier = ref.read(duplicateSearchProvider.notifier);
    final groups = state.groups;
    final exact = groups.where((g) => g.exact).length;
    final hidden = groups.fold<int>(0, (n, g) => n + g.members.length - 1);
    final files = [for (final m in state.merged) ...m.dropped];
    final bytes = files.fold<int>(0, (n, e) => n + e.sizeBytes);
    final header = <Widget>[
      if (files.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            8,
            CcDims.margin,
            4,
          ),
          child: Card(
            color: context.cc.surface2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.duplicatesMerged(files.length))),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('delete-files'),
                      onPressed: () => confirmAndDeleteMerged(context, ref),
                      child: Text(
                        l.duplicatesDeleteFiles(
                          files.length,
                          formatBytes(bytes),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (groups.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(CcDims.margin, 8, CcDims.margin, 4),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                l.duplicatesSummary(groups.length, hidden),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (exact > 0)
                OutlinedButton(
                  key: const ValueKey('merge-all-exact'),
                  onPressed: onMergeAll,
                  child: Text(l.duplicatesMergeAllExact(exact)),
                ),
            ],
          ),
        ),
    ];
    if (groups.isEmpty) {
      return Column(
        children: [
          ...header,
          Expanded(
            child: EmptyState(
              icon: Icons.check_circle_outline_rounded,
              message: l.duplicatesNone,
              actionLabel: l.duplicatesSearchAgain,
              onAction: notifier.start,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      itemCount: header.length + groups.length,
      itemBuilder: (_, i) {
        if (i < header.length) return header[i];
        final g = groups[i - header.length];
        return DuplicateGroupCard(
          key: ValueKey(g.key),
          group: g,
          onMerge: (keepId) async {
            final dropped = g.members.length - 1;
            await notifier.merge(g, keepId);
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(content: Text(l.duplicatesMerged(dropped))),
                );
            }
          },
          onNotDuplicates: () => notifier.notDuplicates(g),
        );
      },
    );
  }
}
