import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio/online_entries.dart';
import '../services/online/youtube_service.dart';
import '../services/shuffle_plus/suggestion_log.dart';
import 'pending_playlist_adds.dart';
import 'player_providers.dart';
import 'shuffle_plus_providers.dart';
import 'youtube_providers.dart';

/// What the user can do with a streamed (suggested) entry of the queue.
class SuggestionActions {
  SuggestionActions({
    required this.online,
    required this.log,
    required this.download,
    required this.removeQueueId,
  });

  final OnlineEntries? online;
  final SuggestionLog log;
  final void Function(YtResult result, {String? tag}) download;
  final Future<void> Function(int id) removeQueueId;

  /// Starts the download; the song joins the library when it arrives.
  bool downloadEntry(int id) {
    final r = online?[id]?.result;
    if (r == null) return false;
    download(r);
    log.setOutcome(r.id, SuggestionOutcome.downloaded);
    return true;
  }

  /// Downloads it and adds it to [playlistId] when the file is ready.
  bool addToPlaylist(int id, int playlistId) {
    final r = online?[id]?.result;
    if (r == null) return false;
    download(r, tag: addToPlaylistTag(playlistId));
    log.setOutcome(r.id, SuggestionOutcome.downloaded);
    return true;
  }

  /// Never suggested again; leaves the queue (the next song plays if it was
  /// the current one).
  Future<void> dislike(int id) async {
    final r = online?[id]?.result;
    if (r != null) log.setOutcome(r.id, SuggestionOutcome.disliked);
    await removeQueueId(id);
  }

  Future<void> remove(int id) => removeQueueId(id);
}

final suggestionActionsProvider = Provider<SuggestionActions>((ref) {
  return SuggestionActions(
    online: ref.watch(onlineEntriesProvider),
    log: ref.watch(suggestionLogProvider),
    download: (r, {tag}) => ref.read(downloadsProvider.notifier).add(r, tag: tag),
    removeQueueId: ref.read(audioHandlerProvider).removeQueueId,
  );
});
