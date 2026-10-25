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
  final Future<bool> Function(YtResult result, {String? tag}) download;
  final Future<void> Function(int id) removeQueueId;

  /// Starts the download (the song joins the library when it arrives) or, with
  /// the file already cached, adds it at once. Null: no such entry; true: added at once.
  Future<bool?> downloadEntry(int id) async {
    final r = online?[id]?.result;
    if (r == null) return null;
    log.setOutcome(r.id, SuggestionOutcome.downloaded);
    return download(r);
  }

  /// Downloads it and adds it to [playlistId] when the file is ready (at once
  /// if cached). Null: no such entry; true: added at once.
  Future<bool?> addToPlaylist(int id, int playlistId) async {
    final r = online?[id]?.result;
    if (r == null) return null;
    log.setOutcome(r.id, SuggestionOutcome.downloaded);
    return download(r, tag: addToPlaylistTag(playlistId));
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
