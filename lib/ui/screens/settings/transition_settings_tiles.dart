import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/audio/audio_backend.dart' show TransitionMode;
import '../../widgets/segmented_blocks.dart';

String transitionLabel(AppLocalizations l, TransitionMode m) => switch (m) {
  TransitionMode.normal => l.transitionNormal,
  TransitionMode.gapless => l.transitionGapless,
  TransitionMode.crossfade => l.transitionCrossfade,
};

const _icons = {
  TransitionMode.normal: Icons.skip_next_rounded,
  TransitionMode.gapless: Icons.link_rounded,
  TransitionMode.crossfade: Icons.blur_linear_rounded,
};

/// «Passaggio tra i brani»: normal, gapless or crossfade, and its options.
class TransitionSettingsTiles extends ConsumerWidget {
  const TransitionSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.swap_horiz_rounded),
          title: Text(l.transitionMode),
          subtitle: Text(l.transitionHint),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(CcDims.gap16, 0, CcDims.gap16, CcDims.gap8),
          child: SegmentedBlocks<TransitionMode>(
            items: [
              for (final m in TransitionMode.values)
                BlockItem(
                  value: m,
                  icon: _icons[m]!,
                  label: transitionLabel(l, m),
                ),
            ],
            selected: s.transition,
            onChanged: (m) => notifier.update((c) => c.copyWith(transition: m)),
          ),
        ),
        if (s.transition == TransitionMode.crossfade) ...[
          ListTile(
            title: Text(l.crossfadeLength(s.crossfadeSeconds)),
            subtitle: Slider(
              min: 2,
              max: 12,
              divisions: 10,
              value: s.crossfadeSeconds.toDouble(),
              label: '${s.crossfadeSeconds} s',
              onChanged: (v) => notifier.update(
                (c) => c.copyWith(crossfadeSeconds: v.round()),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l.crossfadePlainInAlbum),
            subtitle: Text(l.crossfadePlainInAlbumHint),
            value: s.crossfadePlainInAlbum,
            onChanged: (v) =>
                notifier.update((c) => c.copyWith(crossfadePlainInAlbum: v)),
          ),
        ],
      ],
    );
  }
}
