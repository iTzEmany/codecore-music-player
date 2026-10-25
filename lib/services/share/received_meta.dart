import 'dart:typed_data';

import '../../core/app_log.dart';
import '../../data/repositories/credits_repository.dart';
import '../../data/repositories/track_repository.dart';
import '../covers/cover_store.dart';
import 'track_meta.dart';

typedef ReceivedCover = ({Uint8List bytes, String mime});

/// Gives a freshly scanned received file the sender's metadata and cover.
/// Never throws: a failure is logged and the file stays as the scan made it.
Future<void> applyReceivedPackage(
  TrackRepository tracks,
  CoverStore covers,
  String path,
  TrackMeta? meta, {
  Future<ReceivedCover?> Function()? fetchCover,
  CreditsRepository? credits,
}) async {
  try {
    final row = await tracks.byPath(path);
    if (row == null) {
      AppLog.w('received file not in library: $path');
      return;
    }
    final albumKey = meta == null
        ? row.albumKey
        : await tracks.applyReceivedMeta(row.id, meta) ?? row.albumKey;
    if (meta != null && credits != null) await credits.saveIfNone(row.id, meta.credits, meta.details);
    final cover = fetchCover == null ? null : await fetchCover();
    if (cover == null) return;
    final key = await covers.saveFromBytes(albumKey, cover.bytes, cover.mime);
    if (key != null) await tracks.setCoverForAlbum(albumKey, true, key);
  } on Object catch (e, st) {
    AppLog.w('received metadata not applied: $path', e, st);
  }
}
