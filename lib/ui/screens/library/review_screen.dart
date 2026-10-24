import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/review_queries.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/second_opinion_providers.dart';
import '../../../providers/selection_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/selection_bar.dart';
import '../../widgets/track_row.dart';
import '../../widgets/track_row_selection.dart';
import '../enrich_preview_dialog.dart';
import '../../shell/shell_nav.dart';
import 'second_opinion_log_screen.dart';
import '../track_edit_dialog.dart';
import '../../widgets/cc_sheet.dart';
import '../../widgets/show_msg.dart';
import '../../widgets/cc_app_bar.dart';

/// Library → «Da revisionare»: the songs online enrichment found nothing for,
/// or left without lyrics, cover or album/year/genre.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  static const _key = 'review';

  /// Left inset of the reasons line: under the title, past the cover.
  static const _reasonsInset = 72.0;

  /// null = «Tutti».
  ReviewReason? _filter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(reviewActionsProvider).secondOpinionOnOpen();
    });
  }

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

  Future<void> _retry(Set<int> ids) async {
    final l = context.l10n;
    final result = await ref.read(reviewActionsProvider).retry(ids);
    if (!mounted) return;
    ref.read(selectionProvider(_key).notifier).clear();
    showMsg(context, 
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
    showMsg(context, l.reviewDismissed(ids.length));
  }

  void _rowMenu(Track track) {
    final l = context.l10n;
    final page = context;
    showCcSheet<void>(
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
    // The end of a run: say what it did (nothing when it changed nothing).
    ref.listen(secondOpinionJobProvider, (prev, next) {
      if (prev == null || !prev.running || next.running) return;
      final lines = [
        if (next.updated > 0) l.reviewSecondOpinionDone(next.updated),
        if (next.throttled) l.reviewSecondOpinionThrottled,
      ];
      if (lines.isNotEmpty) showMsg(context, lines.join('\n'));
    });
    final job = ref.watch(secondOpinionJobProvider);
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
            : CcAppBar(
                title: l.reviewTitle,
                actions: [
                  if (job.log.isNotEmpty && !job.running)
                    TextButton(
                      key: const ValueKey('review-second-opinion-log'),
                      onPressed: () => ShellNav.open<void>(
                        context,
                        const SecondOpinionLogScreen(),
                      ),
                      child: Text(l.activityLog),
                    ),
                ],
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                if (job.running)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CcDims.margin,
                      0,
                      CcDims.margin,
                      CcDims.gap4,
                    ),
                    child: Row(
                      key: const ValueKey('review-second-opinion'),
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => ShellNav.open<void>(
                              context,
                              const SecondOpinionLogScreen(),
                            ),
                            child: Text(
                              l.reviewSecondOpinionProgress(
                                job.done,
                                job.total,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: context.cc.textMuted),
                            ),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('review-second-opinion-stop'),
                          onPressed: ref
                              .read(secondOpinionJobProvider.notifier)
                              .cancel,
                          child: Text(l.reviewSecondOpinionStop),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CcDims.margin,
                    CcDims.gap4,
                    CcDims.margin,
                    CcDims.gap8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in <ReviewReason?>[
                        null,
                        ...ReviewReason.values,
                      ])
                        ChoiceChip(
                          label: Text(_label(r)),
                          selected: _filter == r,
                          onSelected: (_) {
                            notifier.clear();
                            setState(() => _filter = r);
                          },
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
                                itemBuilder: (_, i) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: extent,
                                      child: LiveTrackRow(
                                        track: tracks[i],
                                        compact: compact,
                                        selection: selection,
                                        onTap: () => _rowMenu(tracks[i]),
                                        onMore: () => _rowMenu(tracks[i]),
                                      ),
                                    ),
                                    // The reasons get their own (up to two) lines
                                    // so a phone does not cut them with «…».
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        _reasonsInset,
                                        0,
                                        CcDims.margin,
                                        6,
                                      ),
                                      child: Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Text(
                                          [
                                            for (final r
                                                in reasons[tracks[i].id]!)
                                              _label(r),
                                          ].join(', '),
                                          key: ValueKey(
                                            'review-reasons-${tracks[i].id}',
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: context.cc.textMuted,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
