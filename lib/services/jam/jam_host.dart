import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/app_log.dart';
import '../share/lan_server.dart';
import '../share/offers.dart';
import 'jam_models.dart';
import 'jam_state.dart';

const jamRequestTtl = Duration(minutes: 5);
const jamPollWait = Duration(seconds: 25);

/// Resolves an item this device owns (via [JamItem.ref]) to a local file.
typedef JamFileResolver = Future<String?> Function(JamItem item);

enum JamRequestStatus { pending, accepted, declined, expired, cancelled }

class JamRequest {
  JamRequest({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.fromHost,
    required this.fromPort,
    required this.token,
    required this.receivedAt,
  });

  final String id, fromId, fromName, fromHost, token;
  final int fromPort;
  final DateTime receivedAt;
  JamRequestStatus status = JamRequestStatus.pending;
  String? sessionId, sessionToken;
}

/// Routes of the Jam protocol, mounted under `/jam` by [OfferNode].
///
/// Both roles use it: the host serves `/request`, `/<sid>/state`, `/<sid>/cmd`;
/// every participant serves `/<sid>/file/<itemId>` for the items it owns,
/// and only for items currently in the queue.
class JamHost {
  JamHost({
    required this.deviceId,
    required this.deviceName,
    this.allowLoopback = false,
    DateTime Function()? now,
    this.pollWait = jamPollWait,
    this.maxRequestsPerMinute = 5,
  }) : _now = now ?? DateTime.now;

  final String deviceId, deviceName;
  final bool allowLoopback;
  final Duration pollWait;
  final int maxRequestsPerMinute;
  final DateTime Function() _now;

  JamFileResolver? resolveFile;

  /// A new valid request arrived (the UI asks the user).
  void Function(JamRequest request)? onRequest;

  final requests = <String, JamRequest>{};
  final _recent = <String, List<DateTime>>{};
  final _changes = StreamController<void>.broadcast();

  // Active session as host.
  JamState? _state;
  String? _sid, _token;
  JamRequest? _guest;

  // Active session as guest (set by the client, see attachGuest).
  String? _gSid, _gToken;
  JamState? Function()? _gState;

  JamState? get state => _state;
  String? get sessionId => _sid;
  String? get sessionToken => _token;
  JamRequest? get guest => _guest;
  bool get hosting => _state != null && !_state!.ended;
  Stream<void> get changes => _changes.stream;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() {
    _changes.close();
  }

  void expire() {
    final limit = _now().subtract(jamRequestTtl);
    for (final r in requests.values) {
      if (r.status == JamRequestStatus.pending && r.receivedAt.isBefore(limit)) {
        r.status = JamRequestStatus.expired;
      }
    }
  }

  // ---- host API ------------------------------------------------------------

  /// Accepts [id]: creates the session and returns its initial state.
  JamState? accept(String id) {
    expire();
    final r = requests[id];
    if (r == null || r.status != JamRequestStatus.pending || hosting) {
      return null;
    }
    r.status = JamRequestStatus.accepted;
    r.sessionId = newToken();
    r.sessionToken = newToken();
    _sid = r.sessionId;
    _token = r.sessionToken;
    _guest = r;
    _state = JamState(
      hostDeviceId: deviceId,
      outputDeviceId: deviceId,
      positionAt: _now().millisecondsSinceEpoch,
    );
    AppLog.i('jam: session started with ${r.fromHost}');
    _notify();
    return _state;
  }

  void decline(String id) {
    final r = requests[id];
    if (r != null && r.status == JamRequestStatus.pending) {
      r.status = JamRequestStatus.declined;
      _notify();
    }
  }

  /// Applies a command issued by the host itself (or an inbound one).
  JamResult apply(JamCommand cmd, {String? from}) {
    final s = _state;
    if (s == null) return const JamResult.fail(JamError.notFound);
    final r = applyCommand(s, cmd,
        from: from ?? deviceId, nowMs: _now().millisecondsSinceEpoch);
    if (r.isOk) {
      _state = r.state;
      _notify();
    }
    return r;
  }

  /// Marks the session ended; the guest sees `ended` on its next poll.
  void endSession() {
    if (_state != null && !_state!.ended) apply(const JamCommand.end());
  }

  /// Drops every trace of the session (after the guest had time to see it).
  void clearSession() {
    _state = null;
    _sid = null;
    _token = null;
    _guest = null;
    _notify();
  }

  // ---- guest API -----------------------------------------------------------

  void attachGuest(String sid, String token, JamState? Function() state) {
    _gSid = sid;
    _gToken = token;
    _gState = state;
  }

  void detachGuest() {
    _gSid = _gToken = null;
    _gState = null;
  }

  // ---- HTTP ----------------------------------------------------------------

  String _ip(Request r, String Function(Request)? override) {
    if (override != null) return override(r);
    final info = r.context['shelf.io.connection_info'];
    return info is HttpConnectionInfo ? info.remoteAddress.address : 'unknown';
  }

  static bool _tokenOk(String? expected, String? given) {
    if (expected == null || given == null || given.length != expected.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ given.codeUnitAt(i);
    }
    return diff == 0;
  }

  static Response _json(Object body, [int status = 200]) => Response(status,
      body: jsonEncode(body), headers: {'content-type': 'application/json'});

  static Response _fail(JamError e) => switch (e) {
        JamError.forbidden => Response.forbidden('forbidden'),
        JamError.notFound => Response.notFound('not found'),
        JamError.invalid => Response(400, body: 'invalid'),
        JamError.full => Response(409, body: 'queue full'),
        JamError.ended => Response(410, body: 'ended'),
      };

  Router buildRouter({String Function(Request)? clientIp}) {
    final router = Router();

    // Host: a device asks to start a Jam.
    router.post('/request', (Request r) async {
      final ip = _ip(r, clientIp);
      if (!isLocalNetworkAddress(ip, allowLoopback: allowLoopback)) {
        return Response.forbidden('local network only');
      }
      expire();
      if (hosting) return Response(409, body: 'busy');
      if (requests.values.any((q) => q.status == JamRequestStatus.pending)) {
        return Response(409, body: 'busy');
      }
      final times = _recent.putIfAbsent(ip, () => []);
      final cutoff = _now().subtract(const Duration(minutes: 1));
      times.removeWhere((t) => t.isBefore(cutoff));
      if (times.length >= maxRequestsPerMinute) {
        return Response(429, body: 'too many requests');
      }
      Object? body;
      try {
        body = jsonDecode(await r.readAsString());
      } on FormatException {
        return Response(400, body: 'bad json');
      }
      if (body is! Map) return Response(400, body: 'bad request');
      final fromId = body['fromId'], fromName = body['fromName'];
      final port = body['port'], token = body['token'];
      if (fromId is! String ||
          fromId.isEmpty ||
          fromId.length > 64 ||
          fromName is! String ||
          port is! int ||
          port < 1 ||
          port > 65535 ||
          token is! String ||
          token.length < 8 ||
          token.length > 64) {
        return Response(400, body: 'bad request');
      }
      times.add(_now());
      final req = JamRequest(
        id: newToken(),
        fromId: fromId,
        fromName: fromName.length > 60 ? fromName.substring(0, 60) : fromName,
        fromHost: ip,
        fromPort: port,
        token: token,
        receivedAt: _now(),
      );
      requests[req.id] = req;
      _notify();
      onRequest?.call(req);
      return _json({'requestId': req.id}, 202);
    });

    // Host: the requester polls the answer (token = its own request token).
    router.get('/request/<id>', (Request r, String id) {
      expire();
      final q = requests[id];
      if (q == null || !_tokenOk(q.token, r.headers['x-token'])) {
        return Response(401, body: 'unauthorized');
      }
      return _json({
        'status': q.status.name,
        'hostId': deviceId,
        'hostName': deviceName,
        if (q.status == JamRequestStatus.accepted) ...{
          'sessionId': q.sessionId,
          'token': q.sessionToken,
        },
      });
    });

    // Host: the requester withdraws.
    router.post('/request/<id>/cancel', (Request r, String id) {
      final q = requests[id];
      if (q == null || !_tokenOk(q.token, r.headers['x-token'])) {
        return Response(401, body: 'unauthorized');
      }
      if (q.status == JamRequestStatus.pending) {
        q.status = JamRequestStatus.cancelled;
        _notify();
      }
      return Response.ok('ok');
    });

    bool hostAuth(Request r, String sid) =>
        _sid != null && sid == _sid && _tokenOk(_token, r.headers['x-jam-token']);

    // Host: state, long polling on `since`.
    router.get('/<sid>/state', (Request r, String sid) async {
      if (!hostAuth(r, sid)) return Response(401, body: 'unauthorized');
      final since = int.tryParse(r.url.queryParameters['since'] ?? '') ?? -1;
      var s = _state;
      if (s == null) return Response.notFound('no session');
      if (s.version <= since && !s.ended) {
        try {
          await _changes.stream.first.timeout(pollWait);
        } on TimeoutException {
          // fall through: the client just polls again
        }
        s = _state ?? s;
      }
      return _json(s.toJson());
    });

    // Host: commands from the guest.
    router.post('/<sid>/cmd', (Request r, String sid) async {
      if (!hostAuth(r, sid)) return Response(401, body: 'unauthorized');
      Object? body;
      try {
        body = jsonDecode(await r.readAsString());
      } on FormatException {
        return Response(400, body: 'bad json');
      }
      final cmd = JamCommand.tryParse(body);
      if (cmd == null) return Response(400, body: 'bad command');
      final from = _guest?.fromId;
      if (from == null) return Response.notFound('no session');
      final res = apply(cmd, from: from);
      if (!res.isOk) return _fail(res.error!);
      return _json(res.state!.toJson());
    });

    // Owner: stream a queued item that this device owns.
    router.get('/<sid>/file/<n>', (Request r, String sid, String n) async {
      final hostSide = _sid != null && sid == _sid;
      final guestSide = _gSid != null && sid == _gSid;
      if (!hostSide && !guestSide) return Response(401, body: 'unauthorized');
      final token = hostSide ? _token : _gToken;
      if (!_tokenOk(token, r.headers['x-jam-token'])) {
        return Response(401, body: 'unauthorized');
      }
      final st = hostSide ? _state : _gState?.call();
      final id = int.tryParse(n);
      final item = id == null || st == null
          ? null
          : st.items.where((i) => i.id == id).firstOrNull;
      // Only items in the queue are ever exposed.
      if (item == null || item.ownerDeviceId != deviceId) {
        return Response.notFound('not found');
      }
      final path = await resolveFile?.call(item);
      if (path == null) return Response.notFound('not found');
      final file = File(path);
      if (!await file.exists()) return Response.notFound('not found');
      final size = await file.length();
      final range = parseRange(r.headers['range'], size);
      if (identical(range, RangeResult.invalid)) {
        return Response(416, headers: {'content-range': 'bytes */$size'});
      }
      final base = {
        'content-type': 'application/octet-stream',
        'accept-ranges': 'bytes',
      };
      if (range.isFull) {
        return Response.ok(file.openRead(),
            headers: {...base, 'content-length': '$size'});
      }
      return Response(206,
          body: file.openRead(range.start, range.end + 1),
          headers: {
            ...base,
            'content-length': '${range.end - range.start + 1}',
            'content-range': 'bytes ${range.start}-${range.end}/$size',
          });
    });

    return router;
  }
}
