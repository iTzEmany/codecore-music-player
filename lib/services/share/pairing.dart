import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/app_log.dart';
import 'offer_node.dart' show callerFingerprint;

/// How long a pairing request lives, and how many wrong PINs it allows.
const kPairingTtl = Duration(minutes: 2);
const kPairingMaxAttempts = 5;
const kPairingRequestsPerMinute = 3;

/// The key-confirmation value: `HMAC-SHA256(PIN, initiatorFp | responderFp)`.
/// Both sides compute it over the fingerprints **they** saw, so a
/// man-in-the-middle with its own certificate cannot make it match.
String pairingProof(String pin, String initiatorFp, String responderFp) =>
    Hmac(sha256, utf8.encode(pin)).convert(utf8.encode('$initiatorFp|$responderFp')).toString();

/// Equal strings without stopping at the first difference.
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

enum PairState { waiting, pinOk, accepted, rejected, expired, blocked }

/// A pairing someone asked for, as the responder sees it.
class PairRequest {
  PairRequest({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.fingerprint,
    required this.pin,
    required this.expiresAt,
  });

  final String id, deviceId, name;

  /// Proven by the signature of the request.
  final String fingerprint;

  /// Six digits, shown on the responder's screen and typed on the other.
  final String pin;
  final DateTime expiresAt;
  int attempts = 0;
  PairState state = PairState.waiting;
}

/// The responder's side of pairing (the device that shows the PIN).
///
/// 1. `POST /request` — the initiator, signed, says who it is; a PIN appears here.
/// 2. `POST /confirm` — it sends the proof built from the PIN typed there.
/// 3. The user here taps «Conferma» ([accept]); `POST /status` then returns this
///    device's identity and both sides save each other as trusted.
class PairingServer {
  PairingServer({
    required this.ownFingerprint,
    required this.ownId,
    required this.ownName,
    DateTime Function()? now,
    Random? random,
  })  : _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  final String ownFingerprint, ownId, ownName;
  final DateTime Function() _now;
  final Random _random;

  /// A request needs the user's attention (show PIN and fingerprint).
  void Function(PairRequest)? onRequest;

  /// The user accepted a request that had the right PIN: save it as trusted.
  void Function(PairRequest)? onPaired;

  final requests = <String, PairRequest>{};
  final _recent = <DateTime>[];

  PairState _stateOf(PairRequest r) {
    if (r.state == PairState.waiting || r.state == PairState.pinOk) {
      if (_now().isAfter(r.expiresAt)) r.state = PairState.expired;
    }
    return r.state;
  }

  String _newId() => List.generate(12, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  String _newPin() => _random.nextInt(1000000).toString().padLeft(6, '0');

  /// The user taps «Conferma»: only a request whose PIN was proven completes.
  bool accept(String requestId) {
    final r = requests[requestId];
    if (r == null || _stateOf(r) != PairState.pinOk) return false;
    r.state = PairState.accepted;
    onPaired?.call(r);
    return true;
  }

  void reject(String requestId) {
    final r = requests[requestId];
    if (r != null && (r.state == PairState.waiting || r.state == PairState.pinOk)) r.state = PairState.rejected;
  }

  Response _json(int code, Map<String, Object?> body) =>
      Response(code, body: jsonEncode(body), headers: {'content-type': 'application/json'});

  Future<Map<String, dynamic>?> _body(Request r) async {
    try {
      final b = jsonDecode(await r.readAsString());
      return b is Map<String, dynamic> ? b : null;
    } on FormatException {
      return null;
    }
  }

  /// Mounted at `/pair` on the HTTPS server only.
  Router buildRouter() {
    final router = Router();

    router.post('/request', (Request r) async {
      final caller = callerFingerprint(r);
      if (caller == null) return _json(401, {'error': 'unsigned'});
      final cutoff = _now().subtract(const Duration(minutes: 1));
      _recent.removeWhere((t) => t.isBefore(cutoff));
      if (_recent.length >= kPairingRequestsPerMinute) return _json(429, {'error': 'too many'});
      final b = await _body(r);
      final id = b?['id'], name = b?['name'];
      if (id is! String || id.isEmpty || id.length > 64 || name is! String) return _json(400, {'error': 'bad request'});
      _recent.add(_now());
      requests.removeWhere((_, v) => _stateOf(v) != PairState.waiting && _stateOf(v) != PairState.pinOk);
      final req = PairRequest(
        id: _newId(),
        deviceId: id,
        name: name.length > 60 ? name.substring(0, 60) : name,
        fingerprint: caller,
        pin: _newPin(),
        expiresAt: _now().add(kPairingTtl),
      );
      requests[req.id] = req;
      AppLog.i('pairing: request from ${req.name}');
      onRequest?.call(req);
      return _json(202, {'requestId': req.id, 'expiresInSeconds': kPairingTtl.inSeconds});
    });

    router.post('/confirm', (Request r) async {
      final caller = callerFingerprint(r);
      final b = await _body(r);
      final req = requests[b?['requestId']];
      if (caller == null || req == null || caller != req.fingerprint) return _json(404, {'error': 'unknown request'});
      final state = _stateOf(req);
      if (state == PairState.blocked) return _json(429, {'error': 'blocked'});
      if (state != PairState.waiting) return _json(409, {'error': state.name});
      final proof = b?['proof'];
      if (proof is! String) return _json(400, {'error': 'bad request'});
      // The initiator saw our certificate; we know our own.
      final expected = pairingProof(req.pin, req.fingerprint, ownFingerprint);
      if (!constantTimeEquals(proof, expected)) {
        req.attempts++;
        if (req.attempts >= kPairingMaxAttempts) {
          req.state = PairState.blocked;
          return _json(429, {'error': 'blocked'});
        }
        return _json(401, {'error': 'wrong pin', 'attemptsLeft': kPairingMaxAttempts - req.attempts});
      }
      req.state = PairState.pinOk;
      return _json(200, {'status': 'pinOk'});
    });

    router.post('/status', (Request r) async {
      final caller = callerFingerprint(r);
      final b = await _body(r);
      final req = requests[b?['requestId']];
      if (caller == null || req == null || caller != req.fingerprint) return _json(404, {'error': 'unknown request'});
      final state = _stateOf(req);
      return _json(200, {
        'status': state.name,
        if (state == PairState.accepted) ...{'id': ownId, 'name': ownName, 'fingerprint': ownFingerprint},
      });
    });
    return router;
  }
}
