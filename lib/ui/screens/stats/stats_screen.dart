import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/stats_queries.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/history_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/segmented_blocks.dart';
import 'stats_charts.dart';

/// «3 h 20 min», or «45 min» under an hour.
String formatListened(AppLocalizations l, int ms) {
  final minutes = (ms / 60000).round();
  if (minutes < 60) return l.durationMinutes(minutes);
  return l.statsHoursMinutes(minutes ~/ 60, minutes % 60);
}

/// What was listened to in a month or a year: totals, the bars, the favourite
/// hour and the most played tracks, artists and albums.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key, this.now});

  /// For tests: the date that counts as today.
  final DateTime? now;

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late DateTime _now;
  late StatsPeriod _period;

  @override
  void initState() {
    super.initState();
    _now = widget.now ?? DateTime.now();
    _period = StatsPeriod.containing(_now, year: false);
  }

  void _setYear(bool year) => setState(
    () => _period = StatsPeriod.containing(_period.start, year: year),
  );

  bool get _canGoNext => _period.next.start.isBefore(_now);

  String _title(String locale) => _period.isYear
      ? '${_period.start.year}'
      : DateFormat.yMMMM(locale).format(_period.start);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final locale = Localizations.localeOf(context).toString();
    final stats = ref.watch(
      periodStatsProvider((
        year: _period.isYear,
        y: _period.start.year,
        m: _period.start.month,
      )),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.statsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CcDims.margin,
                  4,
                  CcDims.margin,
                  0,
                ),
                child: SegmentedBlocks<bool>(
                  items: [
                    BlockItem(
                      value: false,
                      icon: Icons.calendar_view_month_rounded,
                      label: l.statsMonth,
                    ),
                    BlockItem(
                      value: true,
                      icon: Icons.date_range_rounded,
                      label: l.statsYear,
                    ),
                  ],
                  selected: _period.isYear,
                  onChanged: _setYear,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: l.statsPrevious,
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _period = _period.previous),
                  ),
                  Flexible(
                    child: Text(
                      _title(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l.statsNext,
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _canGoNext
                        ? () => setState(() => _period = _period.next)
                        : null,
                  ),
                ],
              ),
              Expanded(
                child: stats.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => loadErrorState(
                    context,
                    e,
                    st,
                    onRetry: () => ref.invalidate(periodStatsProvider),
                  ),
                  data: (s) => s.isEmpty
                      ? EmptyState(
                          icon: Icons.bar_chart_rounded,
                          message: l.statsEmpty,
                        )
                      : _Body(stats: s, locale: locale, cc: cc),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats, required this.locale, required this.cc});

  final PeriodStats stats;
  final String locale;
  final CcColors cc;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context).textTheme;
    final p = stats.period;
    final starts = p.bucketStarts;
    String? label(int i) {
      if (p.isYear) {
        return DateFormat.MMMM(locale)
            .format(starts[i])
            .substring(0, 1)
            .toUpperCase();
      }
      final day = starts[i].day;
      return day == 1 || day % 5 == 0 ? '$day' : null;
    }

    final fav = stats.favouriteHour;
    Widget fact(String title, String value) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CcDims.margin,
        vertical: 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.bodyMedium?.copyWith(color: cc.textMuted)),
          Text(value, style: theme.bodyLarge),
        ],
      ),
    );

    Widget ranking(
      String title,
      List<RankedItem> items, {
      bool cover = false,
    }) => items.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title),
              for (var i = 0; i < items.length; i++)
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: theme.titleMedium?.copyWith(
                              color: cc.textMuted,
                            ),
                          ),
                        ),
                      ),
                      if (cover) ...[
                        CoverImage(
                          coverKey: items[i].coverKey,
                          size: 40,
                          radius: CcDims.rList,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].name ?? l.unknownAlbum,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyLarge,
                            ),
                            Text(
                              [
                                if (items[i].artist != null) items[i].artist!,
                                l.statsPlays(items[i].plays),
                              ].join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: CcDims.margin),
                    ],
                  ),
                ),
            ],
          );

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            16,
            CcDims.margin,
            4,
          ),
          child: Text(
            formatListened(l, stats.playedMs),
            style: theme.displaySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CcDims.margin,
            0,
            CcDims.margin,
            16,
          ),
          child: Text(
            '${l.statsPlays(stats.plays)}, ${l.statsDistinct(stats.distinctTracks)}',
            style: theme.bodyMedium?.copyWith(color: cc.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CcDims.margin),
          child: StatsBars(
            values: stats.msPerBucket,
            labelOf: label,
            semanticsLabel:
                '${formatListened(l, stats.playedMs)}, ${l.statsPlays(stats.plays)}',
          ),
        ),
        const SizedBox(height: 8),
        if (fav != null)
          fact(
            l.statsFavouriteHour,
            '${fav.toString().padLeft(2, '0')}:00–${((fav + 1) % 24).toString().padLeft(2, '0')}:00',
          ),
        if (stats.firstTitle != null && stats.firstAt != null)
          fact(
            l.statsFirstListen,
            l.statsFirstValue(
              stats.firstTitle!,
              DateFormat.MMMd(locale).format(stats.firstAt!),
            ),
          ),
        ranking(l.statsTopTracks, stats.topTracks, cover: true),
        ranking(l.statsTopArtists, stats.topArtists),
        ranking(l.statsTopAlbums, stats.topAlbums, cover: true),
        const SizedBox(height: 24),
      ],
    );
  }
}
