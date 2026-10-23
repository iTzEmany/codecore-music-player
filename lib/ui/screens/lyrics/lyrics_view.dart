import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/translation_providers.dart';
import '../../../services/online/http_client.dart';
import '../../../services/online/lrc_parser.dart';
import '../../../services/online/lrclib_client.dart';
import '../../../services/online/query_cleaner.dart';
import '../../theme/tokens.dart';

/// Plain text of a track's lyrics (copy action), or null.
String? lyricsPlainText(Track t) {
  if (t.lyricsPlain != null) return t.lyricsPlain;
  final synced = t.lyricsSynced;
  if (synced == null) return null;
  final lines = parseLrc(synced);
  return lines.isEmpty ? null : lines.map((e) => e.text).join('\n');
}

/// Synchronised lyrics that scroll by themselves (variable-height rows, the
/// current one near the upper third), or the plain text, or a search button.
/// Used by the Lyrics page and the desktop side panel.
class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key, required this.track});

  final Track track;

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  List<LrcLine> _lines = const [];
  List<GlobalKey> _keys = const [];
  String? _parsedFor;
  int _index = -1;
  bool _searching = false;

  void _ensureParsed(String? synced) {
    if (synced == _parsedFor) return;
    _parsedFor = synced;
    _lines = synced == null ? const [] : parseLrc(synced);
    _keys = [for (var i = 0; i < _lines.length; i++) GlobalKey()];
    _index = -1;
  }

  void _onPosition(Duration pos) {
    if (_lines.isEmpty) return;
    final i = currentLrcIndex(_lines, pos);
    if (i == _index) return;
    setState(() => _index = i);
    if (i < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = i < _keys.length ? _keys[i].currentContext : null;
      if (ctx == null || !ctx.mounted) return;
      final reduce = ref.read(settingsProvider).reducedMotion;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.35,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _search(Track t) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _searching = true);
    LyricsResult? found;
    var limited = false;
    try {
      final c = cleanSearchQuery(t.title, t.artist ?? '');
      found = await ref
          .read(lrclibClientProvider)
          .find(
            title: c.title,
            artist: c.artist,
            album: t.album,
            durationSec: t.durationMs > 0
                ? (t.durationMs / 1000).round()
                : null,
          );
    } on RateLimitedException {
      limited = true;
    }
    if (!mounted) return;
    setState(() => _searching = false);
    if (found == null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(limited ? l.serviceUnavailable : l.lyricsNotFound),
          ),
        );
      return;
    }
    final result = found;
    final db = ref.read(databaseProvider);
    await (db.update(db.tracks)..where((r) => r.id.equals(t.id))).write(
      TracksCompanion(
        lyricsPlain: Value(result.plain),
        lyricsSynced: Value(result.synced),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final track = widget.track;
    ref.listen(positionProvider, (_, next) {
      final p = next.value;
      if (p != null) _onPosition(p);
    });
    _ensureParsed(track.lyricsSynced);
    final tr = ref.watch(lyricsTranslationProvider);
    final translated = tr != null && tr.trackId == track.id ? tr : null;

    if (_lines.isNotEmpty) {
      final ctrl = ref.read(playerControllerProvider);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CcDims.margin,
          24,
          CcDims.margin,
          200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _lines.length; i++)
              InkWell(
                key: _keys[i],
                onTap: () => ctrl.seek(_lines[i].time),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Opacity(
                    opacity: _index < 0
                        ? 0.55
                        : (i == _index ? 1.0 : (i < _index ? 0.55 : 0.35)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lines[i].text.isEmpty ? '♪' : _lines[i].text,
                          style: theme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (translated != null &&
                            translated.synced &&
                            i < translated.lines.length &&
                            translated.lines[i] != _lines[i].text)
                          Text(
                            translated.lines[i],
                            key: ValueKey('translated-$i'),
                            style: theme.titleMedium?.copyWith(
                              color: cc.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    final plain = track.lyricsPlain;
    if (plain != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(CcDims.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              plain,
              style: theme.bodyLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (translated != null && !translated.synced) ...[
              const Divider(height: 32),
              SelectableText(
                translated.lines.join('\n'),
                key: const ValueKey('translated-plain'),
                style: theme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: cc.textMuted,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.noLyrics,
            style: theme.bodyLarge?.copyWith(color: cc.textMuted),
          ),
          const SizedBox(height: 12),
          _searching
              ? const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(minHeight: 2),
                )
              : FilledButton(
                  onPressed: () => _search(track),
                  child: Text(l.searchLyrics),
                ),
        ],
      ),
    );
  }
}
