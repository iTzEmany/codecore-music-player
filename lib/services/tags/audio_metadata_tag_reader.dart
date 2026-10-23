import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../core/app_log.dart';
import 'tag_reader.dart';

class AudioMetadataTagReader implements TagReader {
  const AudioMetadataTagReader();

  @override
  Future<TagInfo> read(String path, {bool withCover = true}) async {
    try {
      // Off the UI thread; TagInfo holds only strings, numbers and bytes.
      return await Isolate.run(() => _parse(path, withCover));
    } on Object catch (e, st) {
      AppLog.w('tag read failed: $path', e, st);
      return const TagInfo();
    }
  }

  static TagInfo _parse(String path, bool withCover) {
    final m = readMetadata(File(path), getImage: withCover);
    final pic = m.pictures.isEmpty ? null : _bestPicture(m.pictures);
    final ms = m.duration?.inMilliseconds;
    final br = m.bitrate;
    final extras = _extras(path);
    return TagInfo(
      title: _clean(m.title),
      artist: _clean(m.artist),
      albumArtist: _clean(m.albumArtist),
      album: _clean(m.album),
      genre: m.genres.isEmpty ? null : _clean(m.genres.first),
      trackNumber: m.trackNumber,
      discNumber: m.discNumber,
      year: (m.year?.year ?? 0) > 0 ? m.year!.year : null,
      durationMs: (ms == null || ms <= 0) ? null : ms,
      // The package may report bps or kbps depending on the container.
      bitrateKbps: br == null || br <= 0
          ? null
          : (br >= 5000 ? br ~/ 1000 : br),
      sampleRateHz: m.sampleRate,
      coverBytes: pic?.bytes,
      coverMime: pic?.mimetype,
      replayGainDb: extras.$1,
      isrc: extras.$2,
    );
  }

  /// One parse for the extras: ReplayGain and ISRC (TSRC / Vorbis ISRC;
  /// m4a has none in the package).
  static (double?, String?) _extras(String path) {
    try {
      final tag = readAllMetadata(File(path), getImage: false);
      return switch (tag) {
        VorbisMetadata t => (
          parseReplayGain(
            t.replayGainTrackGain.isEmpty ? null : t.replayGainTrackGain.first,
          ),
          normalizeIsrc(t.isrc.firstOrNull),
        ),
        Mp3Metadata t => (
          parseReplayGain(
            t.customMetadata.entries
                .where((e) => e.key.toLowerCase() == 'replaygain_track_gain')
                .map((e) => e.value)
                .firstOrNull,
          ),
          normalizeIsrc(t.isrc),
        ),
        _ => (null, null),
      };
    } on Object catch (e, st) {
      AppLog.d('extra tags read skipped: $path', e, st);
      return (null, null);
    }
  }

  static Picture _bestPicture(List<Picture> pics) => pics.firstWhere(
    (p) => p.pictureType == PictureType.coverFront,
    orElse: () => pics.first,
  );

  static String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
