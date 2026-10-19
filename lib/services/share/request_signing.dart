import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';

import 'device_identity.dart';

/// A request signed with the device's key: the proof of «who is calling».
/// TLS here only authenticates the server (a Dart server cannot take a
/// self-signed client certificate), so the caller signs
/// `timestamp, method, path, SHA-256(body)` and sends its certificate. The
/// receiver trusts the call only if the certificate's fingerprint is one it
/// paired with.
const kCertHeader = 'x-codecore-cert';
const kTimeHeader = 'x-codecore-ts';
const kSigHeader = 'x-codecore-sig';

/// A signed request older (or from further ahead) than this is refused.
const kSignatureWindow = Duration(minutes: 2);

const _algorithm = 'SHA-256/ECDSA';

Uint8List _message(int ts, String method, String path, List<int> body) =>
    Uint8List.fromList(utf8.encode('$ts\n${method.toUpperCase()}\n$path\n${sha256.convert(body)}'));

/// The headers to add to a request of [identity].
Map<String, String> signRequest(
  DeviceIdentity identity,
  String method,
  String path,
  List<int> body, {
  DateTime? now,
}) {
  final ts = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final key = CryptoUtils.ecPrivateKeyFromPem(identity.keyPem);
  final sig = CryptoUtils.ecSign(key, _message(ts, method, path, body), algorithmName: _algorithm);
  return {
    kCertHeader: base64.encode(DeviceIdentity.derFromPem(identity.certPem)),
    kTimeHeader: '$ts',
    kSigHeader: CryptoUtils.ecSignatureToBase64(sig),
  };
}

/// The fingerprint of the device that really signed this request, or null if
/// a header is missing, the signature is wrong or the time is off.
String? verifyRequest(
  Map<String, String> headers,
  String method,
  String path,
  List<int> body, {
  DateTime? now,
}) {
  try {
    final certB64 = headers[kCertHeader], tsRaw = headers[kTimeHeader], sig = headers[kSigHeader];
    if (certB64 == null || tsRaw == null || sig == null) return null;
    final ts = int.parse(tsRaw);
    final age = (now ?? DateTime.now()).millisecondsSinceEpoch - ts;
    if (age.abs() > kSignatureWindow.inMilliseconds) return null;
    final der = base64.decode(certB64);
    if (der.length > 4096) return null;
    final pem = '-----BEGIN CERTIFICATE-----\n${base64.encode(der)}\n-----END CERTIFICATE-----';
    final spki = X509Utils.x509CertificateFromPem(pem).tbsCertificate?.subjectPublicKeyInfo.bytes;
    if (spki == null) return null;
    final pub = CryptoUtils.ecPublicKeyFromDerBytes(Uint8List.fromList([
      for (var i = 0; i + 1 < spki.length; i += 2) int.parse(spki.substring(i, i + 2), radix: 16),
    ]));
    final ok = CryptoUtils.ecVerifyBase64(pub, _message(ts, method, path, body), sig, algorithm: _algorithm);
    return ok ? DeviceIdentity.fingerprintOfDer(der) : null;
  } on Object {
    return null; // anything malformed is simply «not proven»
  }
}
