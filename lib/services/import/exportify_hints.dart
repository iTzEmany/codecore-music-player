import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/app_log.dart';

/// How long after «Apri exportify.net» a download is still taken as the one.
const kExportifyWindow = Duration(minutes: 30);

/// The newest `spotify_playlists*.zip` or any `.csv` in [dir] saved after
/// [tapTime], when [now] is within [kExportifyWindow] of the tap; else null.
Future<File?> findExportifyDownload(
  Directory dir,
  DateTime tapTime,
  DateTime now,
) async {
  if (now.difference(tapTime) > kExportifyWindow) return null;
  File? best;
  DateTime? bestAt;
  try {
    await for (final e in dir.list(followLinks: false)) {
      if (e is! File) continue;
      final name = p.basename(e.path).toLowerCase();
      final wanted =
          name.endsWith('.csv') ||
          (name.startsWith('spotify_playlists') && name.endsWith('.zip'));
      if (!wanted) continue;
      final at = (await e.stat()).modified;
      if (!at.isAfter(tapTime)) continue;
      if (bestAt == null || at.isAfter(bestAt)) {
        best = e;
        bestAt = at;
      }
    }
  } on FileSystemException catch (e, st) {
    AppLog.w('Downloads folder not readable', e, st);
  }
  return best;
}

/// Whether the «sync with Spotify» card is due: [remindDays] 0 never; quiet
/// while snoozed; never synced = due; else [remindDays] after the last sync.
bool exportifyReminderDue({
  required int remindDays,
  required int? lastSyncAt,
  required int? snoozeUntil,
  required DateTime now,
}) {
  if (remindDays <= 0) return false;
  final ms = now.millisecondsSinceEpoch;
  if (snoozeUntil != null && ms < snoozeUntil) return false;
  if (lastSyncAt == null) return true;
  return ms >= lastSyncAt + Duration(days: remindDays).inMilliseconds;
}
