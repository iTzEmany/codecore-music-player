import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/translation_providers.dart';
import '../../../services/online/lyrics_translator.dart';

/// Downloaded translation models, each with a delete button.
class TranslationModelsTiles extends ConsumerStatefulWidget {
  const TranslationModelsTiles({super.key});

  @override
  ConsumerState<TranslationModelsTiles> createState() => _State();
}

class _State extends ConsumerState<TranslationModelsTiles> {
  List<String>? _ready;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final translator = ref.read(lyricsTranslatorProvider);
    if (translator == null) return;
    final found = <String>[];
    try {
      for (final lang in translationLanguages.keys) {
        if (await translator.isModelReady(lang)) found.add(lang);
      }
    } on Object catch (e, st) {
      AppLog.e('translation models listing failed', e, st);
    }
    if (!mounted) return;
    setState(() => _ready = found);
  }

  Future<void> _delete(String lang) async {
    try {
      await ref.read(lyricsTranslatorProvider)?.deleteModel(lang);
    } on Object catch (e, st) {
      AppLog.e('translation model delete failed', e, st);
    }
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ready = _ready;
    if (ready == null) {
      return const ListTile(
        title: SizedBox(height: 2, child: LinearProgressIndicator()),
      );
    }
    if (ready.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.translate_rounded),
        title: Text(l.translationModelsNone),
      );
    }
    return Column(
      children: [
        for (final lang in ready)
          ListTile(
            key: ValueKey('model-$lang'),
            leading: const Icon(Icons.translate_rounded),
            title: Text(translationLanguages[lang] ?? lang),
            subtitle: Text('~$translationModelMegabytes MB'),
            trailing: IconButton(
              tooltip: l.translationModelDelete(
                translationLanguages[lang] ?? lang,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(lang),
            ),
          ),
      ],
    );
  }
}
