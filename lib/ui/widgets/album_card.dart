import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/library_queries.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/library_providers.dart';
import '../../providers/preview_providers.dart';
import 'cover_image.dart';
import 'motion.dart';

class AlbumCard extends ConsumerWidget {
  const AlbumCard({super.key, required this.album, required this.onTap});

  final AlbumSummary album;
  final VoidCallback onTap;

  Future<void> _preview(WidgetRef ref) async {
    final tracks = await ref
        .read(libraryQueriesProvider)
        .watchAlbumTracks(album.albumKey)
        .first;
    if (tracks.isNotEmpty) {
      await ref.read(previewProvider.notifier).start(tracks.first);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = album.variousArtists
        ? context.l10n.variousArtists
        : (album.artist ?? context.l10n.unknownArtist);
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => GestureDetector(
                    // Hold the cover: 20 s of the album's first track.
                    onLongPressStart: (_) => _preview(ref),
                    onLongPressEnd: (_) =>
                        ref.read(previewProvider.notifier).stop(),
                    onLongPressCancel: ref.read(previewProvider.notifier).stop,
                    child: CoverImage(
                      coverKey: album.coverKey,
                      size: c.biggest.shortestSide,
                      radius: 8,
                    ),
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
      ),
    );
  }
}
