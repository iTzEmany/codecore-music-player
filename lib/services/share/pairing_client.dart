import 'dart:async';

import 'device_identity.dart';
import 'lan_client.dart';
import 'pairing.dart';

enum PairingError { unreachable, wrongPin, blocked, rejected, expired, cancelled, failed }

class PairingException implements Exception {
  const PairingException(this.error);

  final PairingError error;

  @override
  String toString() => 'PairingException($error)';
}

/// The device that was paired with. [fingerprint] is the certificate it showed
/// during the pairing, not something it claimed.
class PairedPeer {
  const PairedPeer({required this.id, required this.name, required this.fingerprint});

  final String id, name, fingerprint;
}

/// The initiator's side of pairing (the device where the PIN is typed).
class PairingClient {
  PairingClient(this._client, this._identity, {this.pollEvery = const Duration(seconds: 1)});

  final LanClient _client;
  final DeviceIdentity _identity;
  final Duration pollEvery;

  /// [askPin] is called with the fingerprint the peer showed and how many tries
  /// are left (null the first time); it returns the PIN read off the peer's
  /// screen, or null to give up.
  Future<PairedPeer> pair(
    String host,
    int tlsPort, {
    required String ownId,
    required String ownName,
    required Future<String?> Function(String peerFingerprint, int? attemptsLeft) askPin,
  }) async {
    Future<SecureReply> post(String path, Map<String, Object?> body, {String? pin}) async {
      try {
        return await _client.securePost(host, tlsPort, path, body, pin: pin);
      } on LanException catch (e) {
        throw PairingException(e.error == LanError.identityChanged ? PairingError.failed : PairingError.unreachable);
      }
    }

    final first = await post('/pair/request', {'id': ownId, 'name': ownName});
    final seen = first.seenFingerprint;
    if (first.status == 429) throw const PairingException(PairingError.blocked);
    final requestId = first.json?['requestId'];
    if (first.status != 202 || seen == null || requestId is! String) throw const PairingException(PairingError.failed);

    int? left;
    while (true) {
      final pin = await askPin(seen, left);
      if (pin == null) throw const PairingException(PairingError.cancelled);
      final proof = pairingProof(pin.trim(), _identity.fingerprint, seen);
      final r = await post('/pair/confirm', {'requestId': requestId, 'proof': proof}, pin: seen);
      if (r.status == 200) break;
      if (r.status == 429) throw const PairingException(PairingError.blocked);
      if (r.status == 401) {
        left = (r.json?['attemptsLeft'] as num?)?.toInt() ?? 0;
        continue;
      }
      if (r.status == 409 || r.status == 404) throw const PairingException(PairingError.expired);
      throw const PairingException(PairingError.failed);
    }

    // The PIN was right: wait for the person at the other device to confirm.
    final deadline = DateTime.now().add(kPairingTtl);
    while (DateTime.now().isBefore(deadline)) {
      final r = await post('/pair/status', {'requestId': requestId}, pin: seen);
      final status = r.json?['status'];
      if (r.status == 200 && status == 'accepted') {
        final fp = r.json?['fingerprint'];
        final id = r.json?['id'], name = r.json?['name'];
        if (fp is! String || normalizeFp(fp) != normalizeFp(seen) || id is! String) {
          throw const PairingException(PairingError.failed);
        }
        return PairedPeer(id: id, name: '$name', fingerprint: seen);
      }
      if (status == 'rejected') throw const PairingException(PairingError.rejected);
      if (status == 'expired') throw const PairingException(PairingError.expired);
      if (status == 'blocked') throw const PairingException(PairingError.blocked);
      await Future<void>.delayed(pollEvery);
    }
    throw const PairingException(PairingError.expired);
  }
}

String normalizeFp(String s) => s.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
