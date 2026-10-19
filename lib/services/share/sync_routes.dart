import 'dart:convert';
import 'dart:io' show HttpConnectionInfo;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../backup/user_data.dart';
import 'offer_node.dart' show callerFingerprint;
import 'playlist_sync.dart';

/// A request to be sent these tracks («Chiedi i brani mancanti»).
class TrackRequest {
  const TrackRequest({required this.refs, required this.port, this.tlsPort});

  final List<TrackRef> refs;

  /// Where the requester receives offers; the host is the caller's address.
  final int port;
  final int? tlsPort;
}

const kMaxWantedTracks = 500;

/// The sync routes, mounted at `/sync` on the HTTPS server only and answered
/// only to a **trusted** signer: a device that merely knows the address gets 403.
///
/// * `GET /playlists` — every playlist in the portable format.
/// * `POST /want` — «send me these tracks»: answered by an offer in the other direction.
Router buildSyncRouter({
  required Future<List<RemotePlaylist>> Function() export,
  required bool Function(String fingerprint) isTrusted,
  required Future<int> Function(String callerHost, String callerFingerprint, TrackRequest request) onWant,
}) {
  Response json(int code, Object body) =>
      Response(code, body: jsonEncode(body), headers: {'content-type': 'application/json'});

  String? trustedCaller(Request r) {
    final fp = callerFingerprint(r);
    return fp != null && isTrusted(fp) ? fp : null;
  }

  final router = Router();
  router.get('/playlists', (Request r) async {
    if (trustedCaller(r) == null) return json(403, {'error': 'not trusted'});
    return json(200, {'playlists': [for (final p in await export()) p.toJson()]});
  });

  router.post('/want', (Request r) async {
    final fp = trustedCaller(r);
    if (fp == null) return json(403, {'error': 'not trusted'});
    final Object? body;
    try {
      body = jsonDecode(await r.readAsString());
    } on FormatException {
      return json(400, {'error': 'bad json'});
    }
    if (body is! Map || body['refs'] is! List || body['port'] is! int) return json(400, {'error': 'bad request'});
    final raw = body['refs'] as List;
    if (raw.isEmpty || raw.length > kMaxWantedTracks) return json(400, {'error': 'bad count'});
    final tls = body['tlsPort'];
    final info = r.context['shelf.io.connection_info'];
    final host = info is HttpConnectionInfo ? info.remoteAddress.address : '';
    if (host.isEmpty) return json(400, {'error': 'no address'});
    final sent = await onWant(
      host,
      fp,
      TrackRequest(
        refs: [for (final e in raw) if (e is Map<String, dynamic>) TrackRef.fromJson(e)],
        port: body['port'] as int,
        tlsPort: tls is int ? tls : null,
      ),
    );
    return json(202, {'offered': sent});
  });
  return router;
}
