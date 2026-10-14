import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/library_queries.dart';
import '../../../providers/library_providers.dart';
import '../../strings_it.dart';
import '../../widgets/album_grid.dart';
import '../../widgets/empty_state.dart';
import 'album_detail_screen.dart';

class AlbumsTab extends ConsumerWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);
    final sort = ref.watch(albumSortProvider);
    return Column(children: [
      Align(
        alignment: Alignment.centerRight,
        child: PopupMenuButton<AlbumSort>(
          tooltip: S.sortBy,
          icon: const Icon(Icons.sort),
          initialValue: sort,
          onSelected: ref.read(albumSortProvider.notifier).set,
          itemBuilder: (_) => const [
            PopupMenuItem(value: AlbumSort.title, child: Text(S.sortTitle)),
            PopupMenuItem(value: AlbumSort.artist, child: Text(S.sortArtist)),
            PopupMenuItem(value: AlbumSort.year, child: Text(S.sortYear)),
          ],
        ),
      ),
      Expanded(
        child: albums.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) => list.isEmpty
              ? const EmptyState(icon: Icons.album, message: S.noResults)
              : AlbumGrid(
                  albums: list,
                  onOpen: (a) => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => AlbumDetailScreen(album: a))),
                ),
        ),
      ),
    ]);
  }
}
