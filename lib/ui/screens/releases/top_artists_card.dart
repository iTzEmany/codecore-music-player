import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/releases_providers.dart';
import '../../theme/tokens.dart';

/// Shown once in Home: «Vuoi sapere quando escono brani nuovi dei tuoi artisti
/// più ascoltati?». Either answer makes it go away for good.
class TopArtistsCard extends ConsumerWidget {
  const TopArtistsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(releaseOptionsProvider.select((o) => o.topCardSeen));
    if (seen) return const SizedBox.shrink();
    final l = context.l10n;
    final cc = context.cc;
    final options = ref.read(releaseOptionsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 16, CcDims.margin, 0),
      child: Container(
        key: const ValueKey('top-artists-card'),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        decoration: BoxDecoration(
          color: cc.surface1,
          borderRadius: BorderRadius.circular(CcDims.rCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined, color: cc.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.releasesTopCardTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    key: const ValueKey('top-artists-no'),
                    onPressed: options.dismissTopCard,
                    child: Text(l.releasesTopCardNo),
                  ),
                  FilledButton(
                    key: const ValueKey('top-artists-yes'),
                    onPressed: () => options.setTopArtists(true),
                    child: Text(l.releasesTopCardYes),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
