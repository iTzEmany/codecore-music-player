import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/online/http_client.dart';
import '../../../services/online/lrc_parser.dart';
import '../../../services/online/query_cleaner.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_image.dart';
import '../lyrics/lyrics_screen.dart';
import 'queue_sheet.dart';

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.onTap});

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    return Material(
      color: cc.surface1,
      borderRadius: BorderRadius.circular(CcDims.rCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

void _openLyrics(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const LyricsScreen()));

/// Five lines around the current one; tap opens the full lyrics.
class LyricsCard extends ConsumerWidget {
  const LyricsCard({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final synced = track.lyricsSynced;
    final lines = synced == null ? const <LrcLine>[] : parseLrc(synced);
    Widget body;
    if (lines.isNotEmpty) {
      body = _SyncedLines(lines: lines);
    } else if (track.lyricsPlain != null) {
      body = Text(
        track.lyricsPlain!,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: theme.bodyLarge,
      );
    } else {
      body = Row(
        children: [
          Expanded(
            child: Text(
              l.noLyrics,
              style: theme.bodyMedium?.copyWith(color: cc.textMuted),
            ),
          ),
          OutlinedButton(
            onPressed: () => _openLyrics(context),
            child: Text(l.searchLyrics),
          ),
        ],
      );
    }
    return _Card(
      title: l.lyrics,
      onTap: () => _openLyrics(context),
      child: body,
    );
  }
}

class _SyncedLines extends ConsumerWidget {
  const _SyncedLines({required this.lines});

  final List<LrcLine> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cc = context.cc;
    // Only rebuilds when the current line changes, not on every tick.
    final index = ref.watch(
      positionProvider.select(
        (p) => currentLrcIndex(lines, p.value ?? Duration.zero),
      ),
    );
    final center = index < 0 ? 0 : index;
    final from = (center - 2).clamp(0, lines.length - 1);
    final to = (from + 5).clamp(0, lines.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = from; i < to; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              lines[i].text.isEmpty ? '♪' : lines[i].text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: i == index ? 17 : 15,
                fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                color: i == index ? cc.text : cc.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Wikipedia trivia saved on the track; fetched only on an explicit tap.
class InfoCard extends ConsumerStatefulWidget {
  const InfoCard({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends ConsumerState<InfoCard> {
  bool _loading = false;

  Future<void> _fetch() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final t = widget.track;
    setState(() => _loading = true);
    String? error;
    try {
      final c = cleanSearchQuery(t.title, t.artist ?? '');
      final found = await ref
          .read(wikipediaClientProvider)
          .find(c.title, c.artist, ref.read(settingsProvider).language);
      if (found == null) {
        error = l.noResults;
      } else {
        final db = ref.read(databaseProvider);
        await (db.update(db.tracks)..where((r) => r.id.equals(t.id))).write(
          TracksCompanion(curiosities: Value('${found.text}\n${found.source}')),
        );
      }
    } on RateLimitedException {
      error = l.serviceUnavailable;
    } on Object catch (e, st) {
      AppLog.w('curiosity lookup failed', e, st);
      error = l.serviceUnavailable;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final raw = widget.track.curiosities;
    if (raw == null) {
      return _Card(
        title: l.trackInfo,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton(
                  onPressed: _fetch,
                  child: Text(l.searchCuriosity),
                ),
        ),
      );
    }
    final idx = raw.lastIndexOf('\n');
    final text = idx > 0 ? raw.substring(0, idx) : raw;
    final url = idx > 0 ? raw.substring(idx + 1) : null;
    return _Card(
      title: l.trackInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.sourceWikipedia,
                  style: theme.labelSmall?.copyWith(color: cc.textMuted),
                ),
              ),
              if (url != null)
                TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: url));
                    messenger
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(content: Text(l.copied)));
                  },
                  child: Text(l.copyLink),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The next three tracks of the queue and a shortcut to the full queue.
class UpNextCard extends ConsumerWidget {
  const UpNextCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final queue = ref.watch(queueProvider).value ?? const <Track>[];
    ref.watch(currentTrackProvider.select((t) => t.value?.id));
    final at = ref.read(audioHandlerProvider).currentIndex;
    final next = at < 0 ? const <Track>[] : queue.skip(at + 1).take(3).toList();
    return _Card(
      title: l.upNext,
      onTap: () => showQueueSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (next.isEmpty)
            Text(
              l.emptyQueue,
              style: theme.bodyMedium?.copyWith(color: cc.textMuted),
            ),
          for (final t in next)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CoverImage(coverKey: t.coverKey, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyLarge,
                        ),
                        Text(
                          t.artist ?? l.unknownArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showQueueSheet(context),
              child: Text(l.openQueue),
            ),
          ),
        ],
      ),
    );
  }
}
