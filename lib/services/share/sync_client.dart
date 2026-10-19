import '../backup/user_data.dart';
import 'lan_client.dart';
import 'playlist_sync.dart';

enum SyncError { notTrusted, unreachable, identityChanged, failed }

class SyncException implements Exception {
  const SyncException(this.error);

  final SyncError error;

  @override
  String toString() => 'SyncException($error)';
}

/// The initiator side of the sync: reads the other device's playlists and asks
/// for the tracks this one lacks. Always over HTTPS, signed, pinned.
class SyncClient {
  SyncClient(this._client);

  final LanClient _client;

  Never _fail(Object e) {
    if (e is LanException) {
      throw SyncException(e.error == LanError.identityChanged ? SyncError.identityChanged : SyncError.unreachable);
    }
    throw const SyncException(SyncError.failed);
  }

  Future<List<RemotePlaylist>> playlists(String host, int tlsPort, {required String pin}) async {
    try {
      final r = await _client.secureGet(host, tlsPort, '/sync/playlists', pin: pin);
      if (r.status == 403) throw const SyncException(SyncError.notTrusted);
      final list = r.json?['playlists'];
      if (r.status != 200 || list is! List) throw const SyncException(SyncError.failed);
      return [for (final p in list) if (p is Map<String, dynamic>) RemotePlaylist.fromJson(p)];
    } on SyncException {
      rethrow;
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// Asks the other device to offer [refs] back (to [port]/[tlsPort] here).
  /// Returns how many tracks it found and is offering.
  Future<int> want(String host, int tlsPort, List<TrackRef> refs,
      {required String pin, required int port, int? tlsPortHere}) async {
    try {
      final r = await _client.securePost(host, tlsPort, '/sync/want', {
        'refs': [for (final t in refs) t.toJson()],
        'port': port,
        'tlsPort': ?tlsPortHere,
      }, pin: pin);
      if (r.status == 403) throw const SyncException(SyncError.notTrusted);
      if (r.status != 202) throw const SyncException(SyncError.failed);
      return (r.json?['offered'] as num?)?.toInt() ?? 0;
    } on SyncException {
      rethrow;
    } on Object catch (e) {
      _fail(e);
    }
  }
}
