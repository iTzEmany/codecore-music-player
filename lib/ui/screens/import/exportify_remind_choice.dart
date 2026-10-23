import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/exportify_providers.dart';
import '../../widgets/segmented_blocks.dart';

/// Off, 7, 14 or 30 days: how often the Home card asks to sync with Spotify.
class ExportifyRemindChoice extends ConsumerWidget {
  const ExportifyRemindChoice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return SegmentedBlocks<int>(
      items: [
        BlockItem(
          value: 0,
          icon: Icons.notifications_off_outlined,
          label: l.exportifyRemindOff,
        ),
        for (final d in const [7, 14, 30])
          BlockItem(
            value: d,
            icon: Icons.event_repeat_outlined,
            label: l.exportifyRemindDays(d),
          ),
      ],
      selected: ref.watch(exportifyRemindDaysProvider),
      onChanged: (d) => ref.read(exportifyRemindDaysProvider.notifier).set(d),
    );
  }
}
