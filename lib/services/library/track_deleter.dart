import 'dart:io';

import '../../core/app_log.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/track_repository.dart';
import 'duplicate_cleanup.dart';

/// Deletes files through the platform (Android's system dialog); returns the
/// paths that are gone. Null where the platform has no such thing.
typedef PlatformDeleter = Future<List<String>> Function(List<String> paths);

/// What a «delete from the device» pass did.
class TrackDeleteReport {
  const TrackDeleteReport({required this.deleted, required this.failed});

  /// File gone (or already gone) and library row removed.
  final List<Track> deleted;

  /// File still there, row untouched, with the system's reason.
  final Map<Track, String> failed;
}

Future<void> _deleteFile(String path) => File(path).delete();

/// EPERM / EACCES: on Android 11+ the answer for a file another app created.
bool isPermissionDenied(Object e) =>
    e is FileSystemException && const {1, 13}.contains(e.osError?.errorCode);

String failureReason(Object e) =>
    e is FileSystemException ? (e.osError?.message ?? e.message) : '$e';

/// Really deletes songs: the audio file from the device and then the library
/// row (so playlists, favourites, history and tags go with it). A track whose
/// file cannot be deleted stays in the library untouched.
class TrackDeleter {
  TrackDeleter({
    required this.tracks,
    required this.removeFromQueue,
    FileDeleter? deleter,
    this.platform,
  }) : _deleter = deleter ?? _deleteFile;

  final TrackRepository tracks;

  /// Takes the tracks out of the queue and lets the player release them.
  final Future<void> Function(Set<int> ids) removeFromQueue;
  final FileDeleter _deleter;

  /// Only on Android: for the files plain deletion is not allowed to touch.
  final PlatformDeleter? platform;

  /// Podcast episodes (`kind != 0`) are skipped: they have their own cleanup.
  Future<TrackDeleteReport> deleteTracks(List<Track> input) async {
    final byId = {
      for (final t in input)
        if (t.kind == 0) t.id: t,
    };
    final list = byId.values.toList();
    if (list.isEmpty) return const TrackDeleteReport(deleted: [], failed: {});
    await removeFromQueue(byId.keys.toSet());

    final gone = <Track>[];
    final failed = <Track, String>{};
    final denied = <Track, String>{};
    for (final t in list) {
      if (!await File(t.path).exists()) {
        gone.add(t);
        continue;
      }
      try {
        await _deleter(t.path);
        gone.add(t);
      } on Object catch (e, st) {
        AppLog.w('delete track failed: ${t.path}', e, st);
        (platform != null && isPermissionDenied(e) ? denied : failed)[t] =
            failureReason(e);
      }
    }
    if (denied.isNotEmpty) {
      try {
        await platform!([for (final t in denied.keys) t.path]);
      } on Object catch (e, st) {
        AppLog.w('platform delete failed', e, st);
      }
      for (final e in denied.entries) {
        if (await File(e.key.path).exists()) {
          failed[e.key] = e.value;
        } else {
          gone.add(e.key);
        }
      }
    }
    await tracks.deleteTracks([for (final t in gone) t.id]);
    return TrackDeleteReport(deleted: gone, failed: failed);
  }
}
