import 'package:metadata_god/metadata_god.dart';

import '../../core/app_log.dart';
import 'tag_writer.dart';

/// `metadata_god` (Rust, lofty): changes only the fields given and keeps
/// cover, ReplayGain and unknown tags (checked in 21.1).
class MetadataGodTagWriter implements TagWriter {
  MetadataGodTagWriter();

  static const _formats = {'mp3', 'flac', 'm4a', 'ogg'};
  // Process-wide: the Rust library refuses to be initialised twice.
  static Future<void>? _init;

  @override
  bool supports(String format) => _formats.contains(format.toLowerCase());

  Future<void> _ensureInit() async {
    final pending = _init ??= MetadataGod.initialize();
    try {
      await pending;
    } catch (e) {
      _init = null;
      rethrow;
    }
  }

  @override
  Future<void> write(String path, TagChanges c) async {
    try {
      await _ensureInit();
      await MetadataGod.writeMetadata(
        file: path,
        metadata: Metadata(
          title: c.title,
          artist: c.artist,
          album: c.album,
          albumArtist: c.albumArtist,
          year: c.year,
          genre: c.genre,
          trackNumber: c.trackNumber,
        ),
      );
    } catch (e, st) {
      AppLog.e('metadata_god write failed: $path', e, st);
      throw TagWriteException(TagWriteReason.writeFailed, '$e');
    }
  }
}
