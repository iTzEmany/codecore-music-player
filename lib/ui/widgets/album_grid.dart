import 'package:flutter/material.dart';
import '../theme/tokens.dart';

import '../../data/repositories/library_queries.dart';
import 'album_card.dart';

/// As many columns as fit with a cell of at least 168 px (two at the least).
int albumGridColumns(double width) => ((width - 16) / 168).floor().clamp(2, 12);

class AlbumGrid extends StatelessWidget {
  const AlbumGrid({
    super.key,
    required this.albums,
    required this.onOpen,
    this.shrinkWrap = false,
  });

  final List<AlbumSummary> albums;
  final void Function(AlbumSummary) onOpen;

  /// Inside another scrollable: sized by its content, not scrolling itself.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(CcDims.gap8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: albumGridColumns(c.maxWidth),
          childAspectRatio: 0.78,
        ),
        itemCount: albums.length,
        itemBuilder: (_, i) =>
            AlbumCard(album: albums[i], onTap: () => onOpen(albums[i])),
      ),
    );
  }
}
