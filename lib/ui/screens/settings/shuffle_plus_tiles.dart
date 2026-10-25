import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/shuffle_plus_providers.dart';
import '../../widgets/shuffle_plus_text.dart';

/// «Casuale+»: how to turn it on (a note), how often, Wi‑Fi only, and what it is doing now. Used
/// in Settings > Playback and in the sheet of the shuffle button.
class ShufflePlusTiles extends ConsumerWidget {
  const ShufflePlusTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final mode = ref.watch(shuffleModeProvider);
    final plus = mode == ShuffleMode.plus;
    final block = plus ? ref.watch(shufflePlusBlockProvider).value : null;
    final status = !plus
        ? l.shufflePlusOff
        : block == null
            ? l.shufflePlusActive
            : shufflePlusBlockText(l, block);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.shuffle_on_outlined),
          title: Text(l.shufflePlusNote),
        ),
        ListTile(
          title: Text(l.shufflePlusEvery(s.shufflePlusEvery)),
          subtitle: Slider(
            min: 3,
            max: 10,
            divisions: 7,
            value: s.shufflePlusEvery.toDouble(),
            label: '${s.shufflePlusEvery}',
            onChanged: (v) => notifier.update((c) => c.copyWith(shufflePlusEvery: v.round())),
          ),
        ),
        SwitchListTile(
          title: Text(l.shufflePlusUnmeteredOnly),
          subtitle: Text(l.shufflePlusUnmeteredOnlyHint),
          value: s.shufflePlusUnmeteredOnly,
          onChanged: (v) => notifier.update((c) => c.copyWith(shufflePlusUnmeteredOnly: v)),
        ),
        ListTile(
          dense: true,
          title: Text(status, key: const ValueKey('shuffle-plus-status')),
          subtitle: Text(l.shufflePlusData),
        ),
      ],
    );
  }
}
