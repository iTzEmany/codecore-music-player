import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/services/export/playlist_exporter.dart';
import 'package:codecore/ui/screens/playlists/export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('«Esporta tutte le playlist» also writes the favourites', (tester) async {
    final h = await Harness.create(tester, tracks: 2);
    late WidgetRef ref;
    await h.pump(tester, Consumer(builder: (_, r, _) {
      ref = r;
      return const SizedBox();
    }));
    final names = await tester.runAsync(() async {
      final pid = await ref.read(playlistRepositoryProvider).create('Mix');
      final ids = await ref.read(trackRepositoryProvider).watchTracks().first;
      await ref.read(playlistRepositoryProvider).addTracks(pid, [ids.first.id]);
      var archive = await buildPlaylistsArchive(ref,
          format: ExportFormat.m3u8, relativePaths: false, favoritesName: 'Preferiti');
      final without = [for (final f in archive.files) f.name];
      await ref.read(trackRepositoryProvider).setFavorite(ids.last.id, true);
      archive = await buildPlaylistsArchive(ref,
          format: ExportFormat.m3u8, relativePaths: false, favoritesName: 'Preferiti');
      return (without, [for (final f in archive.files) f.name]);
    });
    expect(names!.$1.any((n) => n.contains('Preferiti')), isFalse, reason: 'empty favourites');
    expect(names.$2.where((n) => n.contains('Preferiti')), hasLength(1));
    expect(names.$2.where((n) => n.contains('Mix')), hasLength(1));
    await h.dispose(tester);
  });
}
