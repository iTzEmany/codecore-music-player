import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/library_queries.dart';
import '../../../providers/library_providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../widgets/album_grid.dart';
import '../../widgets/empty_state.dart';
import 'album_detail_screen.dart';
import '../../widgets/error_state.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistsProvider);
    return artists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => loadErrorState(context, e, st,
          onRetry: () => ref.invalidate(artistsProvider)),
      data: (list) => list.isEmpty
          ? EmptyState(icon: Icons.person, message: context.l10n.noResults)
          : ListView.builder(
              itemExtent: 64,
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(a.name ?? context.l10n.unknownArtist,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${context.l10n.albumsCount(a.albumCount)} • ${context.l10n.tracksCount(a.trackCount)}'),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => ArtistDetailScreen(artist: a))),
                );
              },
            ),
    );
  }
}

class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistSummary artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(artistAlbumsProvider(artist.key));
    return Scaffold(
      appBar: AppBar(title: Text(artist.name ?? context.l10n.unknownArtist)),
      body: albums.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => loadErrorState(context, e, st,
            onRetry: () => ref.invalidate(artistAlbumsProvider(artist.key))),
        data: (list) => AlbumGrid(
          albums: list,
          onOpen: (a) => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => AlbumDetailScreen(album: a))),
        ),
      ),
    );
  }
}
