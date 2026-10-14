import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/library_queries.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/online_providers.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/format_utils.dart';
import '../../widgets/track_tile.dart';

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.album});

  final AlbumSummary album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(albumTracksProvider(album.albumKey));
    final compact = ref.watch(settingsProvider).compactMode;
    final artist = album.variousArtists
        ? context.l10n.variousArtists
        : (album.artist ?? context.l10n.unknownArtist);
    return Scaffold(
      appBar: AppBar(
        title: Text(album.title ?? context.l10n.unknownAlbum),
        actions: [
          IconButton(
            tooltip: context.l10n.enrichAlbum,
            icon: const Icon(Icons.travel_explore),
            onPressed: () {
              final ids = (tracks.value ?? const []).map((t) => t.id).toList();
              final ok = ref.read(enrichJobProvider.notifier).start(ids);
              if (!ok) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                      SnackBar(content: Text(context.l10n.enrichBusy)));
              }
            },
          ),
        ],
      ),
      body: tracks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView.builder(
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return _Header(
                album: album,
                artist: artist,
                onPlay: () => ref
                    .read(playerControllerProvider)
                    .playFromList(list, 0),
                onShuffle: () async {
                  final c = ref.read(playerControllerProvider);
                  await c.setShuffle(true);
                  await c.playFromList(list, 0);
                },
              );
            }
            final t = list[i - 1];
            return SizedBox(
              height: trackRowExtent(compact),
              child: LiveTrackTile(
                track: t,
                compact: compact,
                onTap: () => ref
                    .read(playerControllerProvider)
                    .playFromList(list, i - 1),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.album,
    required this.artist,
    required this.onPlay,
    required this.onShuffle,
  });

  final AlbumSummary album;
  final String artist;
  final VoidCallback onPlay, onShuffle;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (album.year != null) '${album.year}',
      context.l10n.tracksCount(album.trackCount),
      formatDuration(album.durationMs),
    ].join(' • ');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CoverImage(coverKey: album.coverKey, size: 140, radius: 12),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(album.title ?? context.l10n.unknownAlbum,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge),
            Text(artist),
            Text(meta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(context.l10n.play)),
              OutlinedButton.icon(
                  onPressed: onShuffle,
                  icon: const Icon(Icons.shuffle),
                  label: Text(context.l10n.shuffle)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
