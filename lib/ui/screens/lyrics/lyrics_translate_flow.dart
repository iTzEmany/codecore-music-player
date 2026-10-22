import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../data/db/app_database.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/translation_providers.dart';
import '../../../services/online/lrc_parser.dart';
import '../../../services/online/lyrics_translator.dart';

/// Source language picked last time, so the next track starts from it.
String _lastSource = 'en';

/// Lines to translate: the timed ones when present, else the plain text.
({bool synced, List<String> lines})? lyricsLinesOf(Track t) {
  final synced = t.lyricsSynced;
  if (synced != null) {
    final parsed = parseLrc(synced);
    if (parsed.isNotEmpty) {
      return (synced: true, lines: [for (final e in parsed) e.text]);
    }
  }
  final plain = t.lyricsPlain;
  if (plain == null || plain.trim().isEmpty) return null;
  return (synced: false, lines: plain.split('\n'));
}

/// Pick the lyrics language, download the missing models (asking first) and
/// translate. Needs a translator: callers check the provider is not null.
Future<void> runTranslateFlow(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final translator = ref.read(lyricsTranslatorProvider);
  final data = lyricsLinesOf(track);
  if (translator == null || data == null) return;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final target = ref.read(settingsProvider).language;
  final from = await showDialog<String>(
    context: context,
    builder: (_) => _SourceDialog(initial: _lastSource, target: target),
  );
  if (from == null || !context.mounted) return;
  _lastSource = from;
  if (from == target) {
    messenger.showSnackBar(SnackBar(content: Text(l.translateSameLanguage)));
    return;
  }
  var ok = true;
  try {
    if (!await ensureTranslationModels(context, translator, [from, target])) return;
    ok = await ref
        .read(lyricsTranslationProvider.notifier)
        .translate(
          trackId: track.id,
          synced: data.synced,
          lines: data.lines,
          from: from,
          to: target,
        );
  } on Object catch (e, st) {
    AppLog.e('translate flow failed', e, st);
    ok = false;
  }
  if (!ok) {
    messenger.showSnackBar(SnackBar(content: Text(l.translateFailed)));
  }
}

/// Makes sure the models of [langs] are on the phone, asking before each
/// download. False when the user declined or a download failed (already said).
Future<bool> ensureTranslationModels(
  BuildContext context,
  LyricsTranslator translator,
  List<String> langs,
) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context, rootNavigator: true);
  for (final lang in langs) {
    if (await translator.isModelReady(lang)) continue;
    if (!context.mounted) return false;
    final go = await _confirmDownload(context, lang);
    if (go != true || !context.mounted) return false;
    _progress(context, l.translateDownloading(translationLanguages[lang]!));
    var ok = true;
    try {
      await translator.downloadModel(lang);
    } on Object catch (e, st) {
      AppLog.e('translation model download failed', e, st);
      ok = false;
    }
    if (nav.canPop()) nav.pop();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l.translateDownloadFailed)));
      return false;
    }
  }
  return true;
}

Future<bool?> _confirmDownload(BuildContext context, String lang) {
  final l = context.l10n;
  final name = translationLanguages[lang]!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.translateDownloadTitle(name)),
      content: Text(l.translateDownloadBody(translationModelMegabytes)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.translateDownload),
        ),
      ],
    ),
  );
}

void _progress(BuildContext context, String text) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    ),
  );
}

class _SourceDialog extends StatefulWidget {
  const _SourceDialog({required this.initial, required this.target});

  final String initial, target;

  @override
  State<_SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends State<_SourceDialog> {
  late String _from = translationLanguages.containsKey(widget.initial)
      ? widget.initial
      : 'en';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.translateLyrics),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _from,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.translateLyricsFrom),
            items: [
              for (final e in translationLanguages.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _from = v ?? _from),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.arrow_forward_rounded, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  translationLanguages[widget.target] ?? widget.target,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.translateLyricsHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _from),
          child: Text(l.translateLyrics),
        ),
      ],
    );
  }
}
