class TagInfo {
  const TagInfo({
    this.title,
    this.artist,
    this.albumArtist,
    this.album,
    this.genre,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.durationMs,
    this.bitrateKbps,
    this.sampleRateHz,
    this.bitDepth,
    this.channels,
    this.coverBytes,
    this.coverMime,
  });

  final String? title, artist, albumArtist, album, genre;
  final int? trackNumber, discNumber, year, durationMs;
  final int? bitrateKbps, sampleRateHz, bitDepth, channels;
  final List<int>? coverBytes;
  final String? coverMime;
}

abstract class TagReader {
  Future<TagInfo> read(String path, {bool withCover = true});
}
