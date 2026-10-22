import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/import/track_matcher.dart';

/// Rows of the «Avanzate» group: how sure a CSV match must be.
class AdvancedSettingsTiles extends ConsumerWidget {
  const AdvancedSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final now = MatchThresholds(
            sure: s.importSureThreshold, review: s.importReviewThreshold)
        .clamped();
    const min = 0.30, max = 0.98;

    void set(double sure, double review) {
      final t = MatchThresholds(sure: sure, review: review).clamped();
      notifier.update((c) => c.copyWith(
          importSureThreshold: t.sure, importReviewThreshold: t.review));
    }

    Widget slider(String title, String hint, double value,
            ValueChanged<double> onChanged) =>
        ListTile(
          title: Text('$title, ${(value * 100).round()}%'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hint),
              Slider(
                value: value.clamp(min, max).toDouble(),
                min: min,
                max: max,
                divisions: 68,
                onChanged: onChanged,
              ),
            ],
          ),
        );

    return Column(
      children: [
        slider(l.importSureThreshold, l.importSureThresholdHint, now.sure,
            (v) => set(v, now.review)),
        slider(l.importReviewThreshold, l.importReviewThresholdHint,
            now.review, (v) => set(now.sure, v)),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: Text(l.importThresholdsReset),
          onTap: () => set(sureThreshold, reviewThreshold),
        ),
      ],
    );
  }
}
