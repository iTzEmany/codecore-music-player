import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/library_queries.dart';
import '../../../providers/library_providers.dart';
import '../../strings_it.dart';
import '../../widgets/album_grid.dart';
import '../../widgets/empty_state.dart';
import 'album_detail_screen.dart';

class ArtistsTab extends ConsumerWidget {
  const ArtistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistsProvider);
    return artists.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) => list.isEmpty
          ? const EmptyState(icon: Icons.person, message: S.noResults)
          : ListView.builder(
              itemExtent: 64,
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(a.name ?? S.unknownArtist,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${S.albumsCount(a.albumCount)} • ${S.tracksCount(a.trackCount)}'),
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
      appBar: AppBar(title: Text(artist.name ?? S.unknownArtist)),
      body: albums.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => AlbumGrid(
          albums: list,
          onOpen: (a) => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => AlbumDetailScreen(album: a))),
        ),
      ),
    );
  }
}
