import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../services/online/download_queue.dart';
import 'database_providers.dart';
import 'youtube_providers.dart';

const _prefix = 'addto:';

/// The download tag that asks for the song to join [playlistId] once it is a
/// library track.
String addToPlaylistTag(int playlistId) => '$_prefix$playlistId';

int? parseAddToPlaylistTag(String? tag) {
  if (tag == null || !tag.startsWith(_prefix)) return null;
  return int.tryParse(tag.substring(_prefix.length));
}

/// Puts a downloaded suggestion into the playlist it was asked for.
class PendingPlaylistAdds {
  PendingPlaylistAdds({
    required Stream<DownloadItem> settled,
    required this.trackIdForPath,
    required this.addTracks,
  }) {
    _sub = settled.listen((i) => unawaited(_onSettled(i)));
  }

  final Future<int?> Function(String path) trackIdForPath;
  final Future<void> Function(int playlistId, List<int> trackIds) addTracks;
  late final StreamSubscription<DownloadItem> _sub;

  Future<void> _onSettled(DownloadItem item) async {
    final playlistId = parseAddToPlaylistTag(item.tag);
    final path = item.path;
    if (playlistId == null || item.status != DownloadStatus.done || path == null) return;
    try {
      final id = await trackIdForPath(path);
      if (id != null) await addTracks(playlistId, [id]);
    } on Object catch (e, st) {
      AppLog.w('add to playlist after download failed', e, st);
    }
  }

  void dispose() => unawaited(_sub.cancel());
}

/// Started by the shell, which reads it.
final pendingPlaylistAddsProvider = Provider<PendingPlaylistAdds>((ref) {
  final adds = PendingPlaylistAdds(
    settled: ref.watch(downloadsProvider.notifier).settled,
    trackIdForPath: ref.watch(trackRepositoryProvider).idForPath,
    addTracks: (playlist, ids) =>
        ref.read(playlistRepositoryProvider).addTracks(playlist, ids),
  );
  ref.onDispose(adds.dispose);
  return adds;
});
