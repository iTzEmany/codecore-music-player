import 'package:flutter/material.dart';

import '../../data/repositories/library_queries.dart';
import 'album_card.dart';

class AlbumGrid extends StatelessWidget {
  const AlbumGrid({super.key, required this.albums, required this.onOpen});

  final List<AlbumSummary> albums;
  final void Function(AlbumSummary) onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.78,
      ),
      itemCount: albums.length,
      itemBuilder: (_, i) =>
          AlbumCard(album: albums[i], onTap: () => onOpen(albums[i])),
    );
  }
}
