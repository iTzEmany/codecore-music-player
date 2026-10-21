import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online/library_overlap.dart';
import 'library_providers.dart';

/// The library's songs of the artist called [name] (as YouTube Music writes
/// it), to mark online songs that are already there. Empty overlap when the
/// library has no such artist.
final localOverlapProvider = Provider.autoDispose.family<LibraryOverlap, String>((ref, name) {
  final artist = localArtistFor(name, ref.watch(artistsProvider).value ?? const []);
  if (artist == null) return LibraryOverlap(const []);
  return LibraryOverlap(ref.watch(artistTracksProvider(artist.key)).value ?? const []);
});
