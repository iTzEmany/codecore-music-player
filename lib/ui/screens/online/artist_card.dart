import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../services/online/google_thumb.dart';
import '../../../services/online/ytm_artist.dart';
import '../../theme/tokens.dart';
import '../../widgets/net_thumbnail.dart';

/// The artist on top of the online results: round photo, name and «Artista ·
/// monthly audience»; a tap opens the artist's page.
class ArtistCard extends StatelessWidget {
  const ArtistCard({super.key, required this.artist, required this.onTap});

  final YtmArtistRef artist;
  final VoidCallback onTap;

  static const photo = 64.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final thumb = artist.thumbnailUrl;
    final audience = artist.audience;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 4, CcDims.margin, 8),
      child: Material(
        key: const ValueKey('artist-card'),
        color: cc.surface1,
        borderRadius: BorderRadius.circular(CcDims.rCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                NetThumbnail(
                  url: thumb == null ? null : googleThumbAt(thumb, (photo * dpr).round()),
                  width: photo,
                  height: photo,
                  icon: Icons.person_rounded,
                  circle: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(artist.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.titleMedium),
                      Text(
                        audience == null || audience.isEmpty
                            ? l.kindArtist
                            : l.ytmArtistWithAudience(audience),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium?.copyWith(color: cc.textMuted),
                      ),
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
