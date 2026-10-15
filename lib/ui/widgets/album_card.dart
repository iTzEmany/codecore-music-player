import 'package:flutter/material.dart';

import '../../data/repositories/library_queries.dart';
import '../../l10n/l10n_ext.dart';
import 'cover_image.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, required this.onTap});

  final AlbumSummary album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final artist = album.variousArtists
        ? context.l10n.variousArtists
        : (album.artist ?? context.l10n.unknownArtist);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => CoverImage(
                  coverKey: album.coverKey,
                  size: c.biggest.shortestSide,
                  radius: 8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              album.title ?? context.l10n.unknownAlbum,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
