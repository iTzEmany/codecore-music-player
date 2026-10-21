import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/translation_providers.dart';
import '../../../services/online/lyrics_translator.dart';

/// Downloaded translation models, each with a delete button.
class TranslationModelsTiles extends ConsumerWidget {
  const TranslationModelsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ready = ref.watch(translationModelsProvider).value;
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
              onPressed: () => ref.read(translationModelsProvider.notifier).delete(lang),
            ),
          ),
      ],
    );
  }
}
