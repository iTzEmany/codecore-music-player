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

/// Wikipedia trivia about the song and about the artist, fetched only on an
/// explicit tap. The song's lives on the track, the artist's is shared by all
/// the tracks of that artist.
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
      final lang = ref.read(settingsProvider).language;
      final wiki = ref.read(wikipediaClientProvider);
      final db = ref.read(databaseProvider);
      // One after the other: Wikipedia answers a burst with HTTP 429.
      final song = await wiki.findSong(c.title, c.artist, lang);
      final artist = c.artist.isEmpty ? null : await wiki.findArtist(c.artist, lang);
      if (song == null && artist == null) {
        error = l.noResults;
      }
      if (song != null) {
        await (db.update(db.tracks)..where((r) => r.id.equals(t.id))).write(
          TracksCompanion(curiosities: Value('${song.text}\n${song.source}')),
        );
      }
      if (artist != null) {
        await ref.read(artistInfoRepositoryProvider).save(
              c.artist,
              body: artist.text,
              source: artist.source,
              lang: artist.lang,
            );
      }
    } on RateLimitedException catch (e) {
      AppLog.w('curiosity lookup refused', e);
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
    final t = widget.track;
    final cleaned = cleanSearchQuery(t.title, t.artist ?? '');
    final artistInfo = ref.watch(artistInfoProvider(cleaned.artist)).value;
    final raw = t.curiosities;
    final spinner = const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    if (raw == null && artistInfo == null) {
      return _Card(
        title: l.fieldCuriosity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: _loading
              ? spinner
              : OutlinedButton(
                  onPressed: _fetch,
                  child: Text(l.searchCuriosity),
                ),
        ),
      );
    }
    final idx = raw?.lastIndexOf('\n') ?? -1;
    return _Card(
      title: l.fieldCuriosity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (raw != null)
            _CuriosityText(
              heading: l.curiositySong,
              text: idx > 0 ? raw.substring(0, idx) : raw,
              url: idx > 0 ? raw.substring(idx + 1) : null,
            )
          else
            Text(
              l.curiosityNoSong,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cc.textMuted),
            ),
          if (artistInfo != null) ...[
            const SizedBox(height: 16),
            _CuriosityText(
              heading: l.curiosityArtist,
              text: artistInfo.body,
              url: artistInfo.sourceUrl,
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: _loading
                ? Padding(padding: const EdgeInsets.all(8), child: spinner)
                : TextButton(onPressed: _fetch, child: Text(l.retry)),
          ),
        ],
      ),
    );
  }
}

/// One block of trivia: a heading, the text (a few lines, all of it on a tap or
/// on «Mostra tutto») and where it comes from.
class _CuriosityText extends StatefulWidget {
  const _CuriosityText({required this.heading, required this.text, this.url});

  final String heading, text;
  final String? url;

  @override
  State<_CuriosityText> createState() => _CuriosityTextState();
}

class _CuriosityTextState extends State<_CuriosityText> {
  static const _collapsedLines = 5;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final style = theme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.heading,
          style: theme.labelLarge?.copyWith(color: cc.accentSoft),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, box) {
            // Is the text longer than the collapsed height? Then it can grow.
            final painter = TextPainter(
              text: TextSpan(text: widget.text, style: style),
              maxLines: _collapsedLines,
              textDirection: Directionality.of(context),
            )..layout(maxWidth: box.maxWidth);
            final longer = painter.didExceedMaxLines;
            painter.dispose();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: longer ? () => setState(() => _open = !_open) : null,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.text,
                      maxLines: _open ? null : _collapsedLines,
                      overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                ),
                if (longer)
                  TextButton(
                    onPressed: () => setState(() => _open = !_open),
                    child: Text(_open ? l.showLess : l.showMore),
                  ),
              ],
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l.sourceWikipedia,
                style: theme.labelSmall?.copyWith(color: cc.textMuted),
              ),
            ),
            if (widget.url != null)
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: widget.url!));
                  messenger
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(content: Text(l.copied)));
                },
                child: Text(l.copyLink),
              ),
          ],
        ),
      ],
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
