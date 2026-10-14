import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/online/http_client.dart';
import '../../../services/online/lrc_parser.dart';
import '../../../services/online/lrclib_client.dart';
import '../../../services/online/query_cleaner.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  static const _rowExtent = 72.0;
  final _scroll = ScrollController();
  List<LrcLine> _lines = const [];
  String? _parsedFor;
  int _index = -1;
  bool _searching = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _ensureParsed(String? synced) {
    if (synced == _parsedFor) return;
    _parsedFor = synced;
    _lines = synced == null ? const [] : parseLrc(synced);
    _index = -1;
  }

  void _onPosition(Duration pos) {
    if (_lines.isEmpty) return;
    final i = currentLrcIndex(_lines, pos);
    if (i == _index) return;
    setState(() => _index = i);
    if (i < 0 || !_scroll.hasClients) return;
    final target = (i * _rowExtent - _scroll.position.viewportDimension / 2 +
            _rowExtent / 2)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if (ref.read(settingsProvider).reducedMotion) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _search(Track t) async {
    final l = context.l10n;
    setState(() => _searching = true);
    LyricsResult? found;
    var limited = false;
    try {
      final c = cleanSearchQuery(t.title, t.artist ?? '');
      found = await ref.read(lrclibClientProvider).find(
            title: c.title,
            artist: c.artist,
            album: t.album,
            durationSec: t.durationMs > 0 ? (t.durationMs / 1000).round() : null,
          );
    } on RateLimitedException {
      limited = true;
    }
    if (!mounted) return;
    setState(() => _searching = false);
    if (found == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
            content: Text(limited ? l.serviceUnavailable : l.lyricsNotFound)));
      return;
    }
    final result = found;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.lyrics),
        content: SingleChildScrollView(
            child: Text(result.plain ?? result.synced ?? '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok != true) return;
    await (ref.read(databaseProvider).update(ref.read(databaseProvider).tracks)
          ..where((r) => r.id.equals(t.id)))
        .write(TracksCompanion(
            lyricsPlain: Value(result.plain),
            lyricsSynced: Value(result.synced)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final track = ref.watch(liveCurrentTrackProvider).value;
    ref.listen(positionProvider, (_, next) {
      final p = next.value;
      if (p != null) _onPosition(p);
    });
    if (track == null) {
      return Scaffold(
          appBar: AppBar(title: Text(l.lyrics)),
          body: Center(child: Text(l.nothingPlaying)));
    }
    _ensureParsed(track.lyricsSynced);
    final plain = track.lyricsPlain ??
        (_lines.isEmpty ? null : _lines.map((e) => e.text).join('\n'));
    final cur = track.curiosities;
    return Scaffold(
      appBar: AppBar(
        title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (plain != null)
            IconButton(
              tooltip: l.copy,
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: plain));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(content: Text(l.copied)));
              },
            ),
        ],
      ),
      body: Column(children: [
        Expanded(child: _lyricsBody(track, plain)),
        if (cur != null) _Curiosity(raw: cur),
      ]),
    );
  }

  Widget _lyricsBody(Track track, String? plain) {
    final l = context.l10n;
    if (_lines.isNotEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return ListView.builder(
        controller: _scroll,
        itemExtent: _rowExtent,
        itemCount: _lines.length,
        itemBuilder: (_, i) => InkWell(
          onTap: () => ref.read(playerControllerProvider).seek(_lines[i].time),
          child: Center(
            child: Text(
              _lines[i].text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: i == _index ? 18 : 16,
                fontWeight: i == _index ? FontWeight.bold : FontWeight.normal,
                color: i == _index ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    if (plain != null) {
      return SingleChildScrollView(
          padding: const EdgeInsets.all(16), child: SelectableText(plain));
    }
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(l.noLyrics),
        const SizedBox(height: 12),
        _searching
            ? const CircularProgressIndicator()
            : FilledButton(
                onPressed: () => _search(track), child: Text(l.searchLyrics)),
      ]),
    );
  }
}

class _Curiosity extends StatelessWidget {
  const _Curiosity({required this.raw});

  final String raw;

  @override
  Widget build(BuildContext context) {
    final idx = raw.lastIndexOf('\n');
    final text = idx > 0 ? raw.substring(0, idx) : raw;
    final url = idx > 0 ? raw.substring(idx + 1) : null;
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l10n.fieldCuriosity,
              style: Theme.of(context).textTheme.titleSmall),
          Text(text),
          const SizedBox(height: 4),
          Text(context.l10n.sourceWikipedia,
              style: Theme.of(context).textTheme.bodySmall),
          if (url != null)
            SelectableText(url, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
