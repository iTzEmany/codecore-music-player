import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/online/google_thumb.dart';
import '../../../services/online/ytm_artist.dart';
import '../../theme/tokens.dart';
import '../../widgets/net_thumbnail.dart';

/// The album on top of the online results when the search is its title:
/// square cover, title and «Album · artist · year»; a tap opens the album.
class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.release, required this.artist, required this.onTap});

  final YtmRelease release;
  final YtmArtistRef? artist;
  final VoidCallback onTap;

  static const cover = 64.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final thumb = release.thumbnailUrl;
    final line = [l.kindAlbum, ?artist?.name, if (release.subtitle.isNotEmpty) release.subtitle];
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, CcDims.gap4, CcDims.margin, CcDims.gap8),
      child: Material(
        key: const ValueKey('album-card'),
        color: cc.surface1,
        borderRadius: BorderRadius.circular(CcDims.rCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(CcDims.gap12),
            child: Row(
              children: [
                NetThumbnail(
                  url: thumb == null ? null : googleThumbAt(thumb, (cover * dpr).round()),
                  width: cover,
                  height: cover,
                  icon: Icons.album_rounded,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(release.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.titleMedium),
                      Text(line.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodyMedium?.copyWith(color: cc.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cc.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
