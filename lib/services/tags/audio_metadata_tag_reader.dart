import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../core/app_log.dart';
import 'tag_reader.dart';

class AudioMetadataTagReader implements TagReader {
  const AudioMetadataTagReader();

  @override
  Future<TagInfo> read(String path, {bool withCover = true}) async {
    try {
      final m = readMetadata(File(path), getImage: withCover);
      final pic = m.pictures.isEmpty ? null : _bestPicture(m.pictures);
      final ms = m.duration?.inMilliseconds;
      final br = m.bitrate;
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
        bitrateKbps: br == null || br <= 0 ? null : (br >= 5000 ? br ~/ 1000 : br),
        sampleRateHz: m.sampleRate,
        coverBytes: pic?.bytes,
        coverMime: pic?.mimetype,
        replayGainDb: _replayGain(path),
      );
    } on Object catch (e, st) {
      AppLog.w('tag read failed: $path', e, st);
      return const TagInfo();
    }
  }

  double? _replayGain(String path) {
    try {
      final tag = readAllMetadata(File(path), getImage: false);
      return switch (tag) {
        VorbisMetadata t => parseReplayGain(
            t.replayGainTrackGain.isEmpty ? null : t.replayGainTrackGain.first),
        Mp3Metadata t => parseReplayGain(
            t.customMetadata.entries
                .where((e) => e.key.toLowerCase() == 'replaygain_track_gain')
                .map((e) => e.value)
                .firstOrNull),
        _ => null,
      };
    } on Object catch (e, st) {
      AppLog.d('replaygain read skipped: $path', e, st);
      return null;
    }
  }

  Picture _bestPicture(List<Picture> pics) => pics.firstWhere(
        (p) => p.pictureType == PictureType.coverFront,
        orElse: () => pics.first,
      );

  String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
