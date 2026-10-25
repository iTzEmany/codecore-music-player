import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_ext.dart';
import '../../services/online/artist_link_resolver.dart';
import '../theme/tokens.dart';
import 'artist_link_open.dart';
import 'cc_sheet.dart';

/// «Vai all'artista»: no artist does nothing, one opens its page, several ask which.
Future<void> goToArtists(
  BuildContext outer,
  WidgetRef ref,
  List<ArtistName> artists,
) async {
  if (artists.isEmpty) return;
  if (artists.length == 1) return openArtistLink(outer, ref, artists.first);
  final picked = await showCcSheet<ArtistName>(
    context: outer,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => TrackArtistsSheet(artists: artists),
  );
  if (picked != null && outer.mounted) await openArtistLink(outer, ref, picked);
}

/// The artists credited on a track, one per row; popping returns the tapped one.
class TrackArtistsSheet extends StatelessWidget {
  const TrackArtistsSheet({super.key, required this.artists});

  final List<ArtistName> artists;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CcDims.margin,
                0,
                CcDims.margin,
                CcDims.gap8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.artists,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final a in artists)
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(context, a),
              ),
          ],
        ),
      ),
    );
  }
}
