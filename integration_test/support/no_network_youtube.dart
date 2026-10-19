import 'dart:io';

import 'package:codecore/services/online/youtube_service.dart';
import 'package:dio/dio.dart' show CancelToken;

/// A YouTube service that has nothing and counts the searches it is asked.
class NoNetworkYoutube implements YoutubeService {
  int searches = 0;

  @override
  Future<List<YtResult>> search(String query) async {
    searches++;
    return const [];
  }

  @override
  Future<List<YtResult>> searchSongs(String query, {int limit = 5}) async {
    searches++;
    return const [];
  }

  @override
  Future<List<YtResult>> searchSoundCloud(String query, {int limit = 5}) async {
    searches++;
    return const [];
  }

  @override
  Future<List<YtResult>> searchAlbums(String query, {int limit = 3}) async {
    searches++;
    return const [];
  }

  @override
  Future<List<YtResult>> albumTracks(String albumLink) async => const [];

  @override
  Future<PlaylistListing> listPlaylist(String url, {int limit = 500}) async => const PlaylistListing.empty();

  @override
  Stream<DownloadProgress> download(YtResult r, Directory outDir,
          {CancelToken? cancel, DownloadOptions options = const DownloadOptions()}) =>
      const Stream.empty();

  @override
  Future<String?> toolVersion() async => null;

  @override
  void close() {}
}
