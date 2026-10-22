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
import '../../../providers/translation_providers.dart';
import '../../../services/online/http_client.dart';
import '../../../services/online/lrc_parser.dart';
import '../../../services/online/lyrics_translator.dart';
import '../../../services/online/query_cleaner.dart';
import '../../theme/tokens.dart';
import '../lyrics/lyrics_screen.dart';
import '../lyrics/lyrics_translate_flow.dart';
import 'queue_sheet.dart';
import '../../widgets/track_art.dart';

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

  /// What the last search could not do, per part: true = Wikipedia refused (too
  /// many requests), so «nothing found» would be a lie.
  bool _searched = false, _songLimited = false, _artistLimited = false;

  Future<void> _fetch() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final t = widget.track;
    setState(() {
      _loading = true;
      _songLimited = _artistLimited = false;
    });
    final c = cleanSearchQuery(t.title, t.artist ?? '');
    final lang = ref.read(settingsProvider).language;
    final db = ref.read(databaseProvider);
    var limited = false, failed = false;

    // Identity first (MusicBrainz → Wikidata → the exact pages), the names
    // after; each part reports on its own, so one failing does not lose the other.
    final found = await ref.read(curiosityFinderProvider).find(c.title, c.artist, lang);
    final song = found.song, artist = found.artist;
    final songDone = found.songError == null;
    for (final (err, isSong) in [(found.songError, true), (found.artistError, false)]) {
      if (err == null) continue;
      if (err is RateLimitedException) {
        AppLog.w('curiosity refused', err);
        limited = true;
        isSong ? _songLimited = true : _artistLimited = true;
      } else {
        AppLog.w('curiosity lookup failed', err);
        failed = true;
      }
    }
    try {
      // A new search replaces what was saved before, also with nothing: an
      // older version could have saved the artist's page as the song's. A part
      // that could not be asked is left as it was.
      if (songDone) {
        await (db.update(db.tracks)..where((r) => r.id.equals(t.id))).write(
          TracksCompanion(
            curiosities: Value(song == null ? null : '${song.text}\n${song.source}'),
          ),
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
    } on Object catch (e, st) {
      AppLog.w('could not save the curiosities', e, st);
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _searched = true;
    });
    final nothing = song == null && artist == null;
    if (limited || failed || nothing) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(limited || failed ? l.serviceUnavailable : l.noResults),
        ));
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
    if (raw == null && artistInfo == null && !_searched) {
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
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: cc.textMuted);
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
              lang: wikiLangOf(idx > 0 ? raw.substring(idx + 1) : null),
            )
          else
            Text(
              _songLimited ? l.serviceUnavailable : l.curiosityNoSong,
              key: const ValueKey('curiosity-no-song'),
              style: muted,
            ),
          const SizedBox(height: 16),
          if (artistInfo != null)
            _CuriosityText(
              heading: l.curiosityArtist,
              text: artistInfo.body,
              url: artistInfo.sourceUrl,
              lang: artistInfo.lang,
            )
          else
            Text(
              cleaned.artist.isEmpty
                  ? l.unknownArtist
                  : _artistLimited
                  ? l.serviceUnavailable
                  : l.curiosityNoArtist,
              key: const ValueKey('curiosity-no-artist'),
              style: muted,
            ),
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

/// `it` for `https://it.wikipedia.org/wiki/…`; null when it cannot be told.
String? wikiLangOf(String? url) {
  final host = url == null ? null : Uri.tryParse(url.trim())?.host;
  final m = host == null ? null : RegExp(r'^([a-z-]+)\.wikipedia\.org$').firstMatch(host);
  return m?.group(1);
}

/// One block of trivia: a heading, the text (a few lines, all of it on a tap or
/// on «Mostra tutto») and where it comes from. When it is in another language
/// than the app's and the phone can translate, «Traduci» shows it translated.
class _CuriosityText extends ConsumerStatefulWidget {
  const _CuriosityText({
    required this.heading,
    required this.text,
    this.url,
    this.lang,
  });

  final String heading, text;
  final String? url;

  /// Language of [text] (Wikipedia's code), if known.
  final String? lang;

  @override
  ConsumerState<_CuriosityText> createState() => _CuriosityTextState();
}

class _CuriosityTextState extends ConsumerState<_CuriosityText> {
  static const _collapsedLines = 5;
  bool _open = false;
  bool _busy = false;
  String? _translated;

  @override
  void didUpdateWidget(_CuriosityText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _translated = null; // a new search brought other text
  }

  Future<void> _translate(String from, String to) async {
    final translator = ref.read(lyricsTranslatorProvider);
    if (translator == null) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    var ok = false;
    try {
      if (!await ensureTranslationModels(context, translator, [from, to])) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      // Paragraphs one by one: the model keeps the sense of each.
      final parts = widget.text.split('\n');
      final out = await translateKeepingLayout(translator, parts, from: from, to: to);
      if (mounted) setState(() => _translated = out.join('\n'));
      ok = true;
    } on Object catch (e, st) {
      AppLog.e('curiosity translation failed', e, st);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.translateFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final style = theme.bodyLarge;
    final appLang = ref.watch(settingsProvider).language;
    final from = widget.lang;
    final canTranslate = ref.watch(lyricsTranslatorProvider) != null &&
        from != null &&
        from != appLang &&
        translationLanguages.containsKey(from) &&
        translationLanguages.containsKey(appLang);
    final shown = _translated ?? widget.text;
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
              text: TextSpan(text: shown, style: style),
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
                      shown,
                      maxLines: _open ? null : _collapsedLines,
                      overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                ),
                Wrap(
                  children: [
                    if (longer)
                      TextButton(
                        onPressed: () => setState(() => _open = !_open),
                        child: Text(_open ? l.showLess : l.showMore),
                      ),
                    if (canTranslate)
                      _busy
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : TextButton.icon(
                              key: const ValueKey('curiosity-translate'),
                              onPressed: _translated == null
                                  ? () => _translate(from, appLang)
                                  : () => setState(() => _translated = null),
                              icon: Icon(
                                _translated == null ? Icons.translate_rounded : Icons.undo_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _translated == null ? l.translateLyrics : l.translateRemove,
                              ),
                            ),
                  ],
                ),
              ],
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                switch (Uri.tryParse(widget.url ?? '')?.host) {
                  final h? when h.endsWith('discogs.com') => l.curiositySourceDiscogs,
                  final h? when h.endsWith('youtube.com') => l.sourceYoutubeMusic,
                  _ => l.sourceWikipedia,
                },
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
                  TrackArt(track: t, size: 40),
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
