import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/review_queries.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import '../enrich_preview_dialog.dart';
import '../track_edit_dialog.dart';

/// Library → «Da revisionare»: the songs online enrichment found nothing for,
/// or left without lyrics, cover or album/year/genre.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  static const _key = 'review';

  /// null = «Tutti».
  ReviewReason? _filter;

  String _label(ReviewReason? r) {
    final l = context.l10n;
    return switch (r) {
      null => l.reviewFilterAll,
      ReviewReason.nothingFound => l.reviewFilterNothingFound,
      ReviewReason.noLyrics => l.reviewFilterNoLyrics,
      ReviewReason.noCover => l.reviewFilterNoCover,
      ReviewReason.missingData => l.reviewFilterMissingData,
    };
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _retry(Set<int> ids) async {
    final l = context.l10n;
    final result = await ref.read(reviewActionsProvider).retry(ids);
    if (!mounted) return;
    ref.read(selectionProvider(_key).notifier).clear();
    _snack(
      result == ReviewRetryResult.busy
          ? l.enrichBusy
          : l.reviewRetryStarted(ids.length),
    );
  }

  Future<void> _dismiss(Set<int> ids) async {
    final l = context.l10n;
    await ref.read(reviewActionsProvider).dismiss(ids);
    if (!mounted) return;
    ref.read(selectionProvider(_key).notifier).clear();
    _snack(l.reviewDismissed(ids.length));
  }

  void _rowMenu(Track track) {
    final l = context.l10n;
    final page = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        Widget tile(IconData icon, String label, VoidCallback run) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.of(sheet).pop();
            run();
          },
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(
                Icons.travel_explore_rounded,
                l.searchWeb,
                () => showEnrichPreview(page, track),
              ),
              tile(
                Icons.edit_outlined,
                l.editInfo,
                () => showTrackEditDialog(page, track),
              ),
              tile(
                Icons.refresh_rounded,
                l.reviewRetry,
                () => _retry({track.id}),
              ),
              tile(
                Icons.check_circle_outline_rounded,
                l.reviewDismiss,
                () => _dismiss({track.id}),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(reviewTracksProvider).value ?? const <Track>[];
    final reasons = {for (final t in all) t.id: reviewReasons(t)};
    final tracks = [
      for (final t in all)
        if (_filter == null || reasons[t.id]!.contains(_filter)) t,
    ];
    final compact = ref.watch(settingsProvider).compactMode;
    final picked = ref.watch(selectionProvider(_key));
    final notifier = ref.read(selectionProvider(_key).notifier);
    final selection = RowSelection(
      listKey: _key,
      visibleIds: [for (final t in tracks) t.id],
    );
    final extent = trackRowExtentOf(context, compact);
    return SelectionScope(
      listKey: _key,
      visibleIds: selection.visibleIds,
      child: Scaffold(
        appBar: picked.active
            ? PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: SelectionBarFrame(
                  count: picked.count,
                  onClose: notifier.clear,
                  onSelectAll: () => notifier.selectAll(selection.visibleIds),
                  actions: [
                    IconButton(
                      key: const ValueKey('review-retry'),
                      tooltip: l.reviewRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => _retry(picked.ids),
                    ),
                    IconButton(
                      key: const ValueKey('review-dismiss'),
                      tooltip: l.reviewDismiss,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      onPressed: () => _dismiss(picked.ids),
                    ),
                  ],
                ),
              )
            : AppBar(title: Text(l.reviewTitle)),
        body: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
                children: [
                  for (final r in <ReviewReason?>[null, ...ReviewReason.values])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_label(r)),
                        selected: _filter == r,
                        onSelected: (_) {
                          notifier.clear();
                          setState(() => _filter = r);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: tracks.isEmpty
                  ? EmptyState(
                      icon: Icons.fact_check_outlined,
                      message: l.reviewEmpty,
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(CcDims.margin),
                          child: Text(
                            l.reviewHint,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: context.cc.textMuted),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: tracks.length,
                            itemExtent: extent,
                            itemBuilder: (_, i) => LiveTrackRow(
                              track: tracks[i],
                              compact: compact,
                              selection: selection,
                              subtitleSuffix: [
                                for (final r in reasons[tracks[i].id]!)
                                  _label(r),
                              ].join(' · '),
                              onTap: () => _rowMenu(tracks[i]),
                              onMore: () => _rowMenu(tracks[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
