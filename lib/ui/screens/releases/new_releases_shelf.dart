import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/release_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/releases_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/motion.dart';
import '../../widgets/net_thumbnail.dart';
import '../../widgets/section_header.dart';
import '../online/artist_page_sections.dart' show thumbAt;
import 'new_releases_screen.dart';
import 'release_labels.dart';

const _cover = 140.0;

/// «Nuove uscite» in Home: the releases seen in the last 30 days, ten at most.
/// Nothing at all while there are none.
class HomeNewReleasesShelf extends ConsumerWidget {
  const HomeNewReleasesShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list =
        ref.watch(recentReleasesProvider(30)).value ?? const <RecentRelease>[];
    if (list.isEmpty) return const SizedBox.shrink();
    final shown = list.take(10).toList();
    final scaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          l.newReleasesTitle,
          actionLabel: l.newReleasesShowAll,
          onAction: () =>
              ShellNav.open<void>(context, const NewReleasesScreen()),
        ),
        SizedBox(
          height: _cover + 24 + scaler.scale(78),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin - 6),
            itemCount: shown.length,
            itemBuilder: (_, i) => EnterOnce(
              index: i,
              child: ReleaseCard(release: shown[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// One release as a card: cover with the «new» dot, title, artist, «Album · 2026».
class ReleaseCard extends ConsumerWidget {
  const ReleaseCard({super.key, required this.release});

  final RecentRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final r = release.release;
    return PressScale(
      child: InkWell(
        key: ValueKey('new-release-${r.browseId}'),
        borderRadius: BorderRadius.circular(CcDims.rGrid),
        onTap: () => openRelease(context, ref, release),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: _cover,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    NetThumbnail(
                      url: thumbAt(context, r.thumbUrl, _cover),
                      width: _cover,
                      height: _cover,
                      radius: CcDims.rGrid,
                      icon: Icons.album_rounded,
                    ),
                    if (r.isNew)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Semantics(
                          label: l.releaseNewBadge,
                          child: Container(
                            key: ValueKey('new-dot-${r.browseId}'),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cc.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: cc.bg, width: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyLarge,
                ),
                Text(
                  release.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium,
                ),
                Text(
                  releaseKindLabel(l, r),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall?.copyWith(color: cc.textMuted),
                ),
                if (release.variants > 0)
                  Text(
                    l.releaseVariants(release.variants),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall?.copyWith(color: cc.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
