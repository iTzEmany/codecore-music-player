import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import '../../../core/app_log.dart';

/// Only the libsodium primitives the remote Jam protocol needs (D-250, D-252).
abstract interface class JamCrypto {
  Uint8List randomBytes(int length);
  SecureKey keyFromBytes(Uint8List bytes);
  Uint8List keyBytes(SecureKey key);

  KeyPair kxKeyPair();

  /// Null for a low-order or invalid peer public key.
  SessionKeys? kxClientSessionKeys({
    required Uint8List clientPublicKey,
    required SecureKey clientSecretKey,
    required Uint8List serverPublicKey,
  });

  /// Null for a low-order or invalid peer public key.
  SessionKeys? kxServerSessionKeys({
    required Uint8List serverPublicKey,
    required SecureKey serverSecretKey,
    required Uint8List clientPublicKey,
  });

  SecureKey hkdfExtract({Uint8List? salt, required Uint8List ikm});
  SecureKey hkdfExpand({
    required SecureKey prk,
    required String context,
    required int outLen,
  });

  /// Returns `nonce(24) || ciphertext || tag(16)`; the nonce comes from [randomBytes].
  Uint8List aeadEncrypt({
    required SecureKey key,
    required Uint8List message,
    Uint8List? additionalData,
  });

  /// Null when authentication fails or the input is too short.
  Uint8List? aeadDecrypt({
    required SecureKey key,
    required Uint8List nonceAndCipher,
    Uint8List? additionalData,
  });

  /// HMAC-SHA-512-256, 32 B tag.
  Uint8List mac({required SecureKey key, required Uint8List message});
  bool macVerify({
    required SecureKey key,
    required Uint8List message,
    required Uint8List tag,
  });

  Uint8List genericHash(Uint8List message, {required int outLen});

  /// Argon2id (interactive limits) raw output, computed in a separate isolate.
  Future<SecureKey> pwhash({
    required String password,
    required Uint8List salt,
    required int outLen,
  });

  Uint8List pad(Uint8List data, int blockSize);

  /// Null when the padding is invalid.
  Uint8List? unpad(Uint8List data, int blockSize);
}

class SodiumJamCrypto implements JamCrypto {
  SodiumJamCrypto._(this._s, Uint8List Function(int)? random)
    : _random = random ?? _s.randombytes.buf;

  /// [random] replaces `randombytes.buf` (nonces and key seeds) in tests.
  static Future<SodiumJamCrypto> create({
    Uint8List Function(int)? random,
  }) async => SodiumJamCrypto._(await SodiumSumoInit.init(), random);

  final SodiumSumo _s;
  final Uint8List Function(int) _random;

  CryptoSumo get _c => _s.crypto;

  @override
  Uint8List randomBytes(int length) => _random(length);

  @override
  SecureKey keyFromBytes(Uint8List bytes) => _s.secureCopy(bytes);

  @override
  Uint8List keyBytes(SecureKey key) =>
      key.runUnlockedSync((b) => Uint8List.fromList(b));

  @override
  KeyPair kxKeyPair() {
    final raw = _random(_c.kx.seedBytes);
    final seed = _s.secureCopy(raw);
    raw.fillRange(0, raw.length, 0);
    try {
      return _c.kx.seedKeyPair(seed);
    } finally {
      seed.dispose();
    }
  }

  @override
  SessionKeys? kxClientSessionKeys({
    required Uint8List clientPublicKey,
    required SecureKey clientSecretKey,
    required Uint8List serverPublicKey,
  }) {
    try {
      return _c.kx.clientSessionKeys(
        clientPublicKey: clientPublicKey,
        clientSecretKey: clientSecretKey,
        serverPublicKey: serverPublicKey,
      );
    } on SodiumException catch (e) {
      AppLog.d('jam kx client: peer key refused', e);
      return null;
    }
  }

  @override
  SessionKeys? kxServerSessionKeys({
    required Uint8List serverPublicKey,
    required SecureKey serverSecretKey,
    required Uint8List clientPublicKey,
  }) {
    try {
      return _c.kx.serverSessionKeys(
        serverPublicKey: serverPublicKey,
        serverSecretKey: serverSecretKey,
        clientPublicKey: clientPublicKey,
      );
    } on SodiumException catch (e) {
      AppLog.d('jam kx server: peer key refused', e);
      return null;
    }
  }

  @override
  SecureKey hkdfExtract({Uint8List? salt, required Uint8List ikm}) =>
      _c.kdfHkdfSha256.extract(salt: salt, ikm: ikm);

  @override
  SecureKey hkdfExpand({
    required SecureKey prk,
    required String context,
    required int outLen,
  }) =>
      _c.kdfHkdfSha256.expand(masterKey: prk, context: context, outLen: outLen);

  @override
  Uint8List aeadEncrypt({
    required SecureKey key,
    required Uint8List message,
    Uint8List? additionalData,
  }) {
    final aead = _c.aeadXChaCha20Poly1305IETF;
    final nonce = _random(aead.nonceBytes);
    final ct = aead.encrypt(
      message: message,
      nonce: nonce,
      key: key,
      additionalData: additionalData,
    );
    return Uint8List.fromList([...nonce, ...ct]);
  }

  @override
  Uint8List? aeadDecrypt({
    required SecureKey key,
    required Uint8List nonceAndCipher,
    Uint8List? additionalData,
  }) {
    final aead = _c.aeadXChaCha20Poly1305IETF;
    if (nonceAndCipher.length < aead.nonceBytes + aead.aBytes) return null;
    try {
      return aead.decrypt(
        cipherText: Uint8List.sublistView(nonceAndCipher, aead.nonceBytes),
        nonce: Uint8List.sublistView(nonceAndCipher, 0, aead.nonceBytes),
        key: key,
        additionalData: additionalData,
      );
    } on SodiumException {
      return null; // forged or corrupted message: the caller drops and counts it
    }
  }

  @override
  Uint8List mac({required SecureKey key, required Uint8List message}) =>
      _c.auth(message: message, key: key);

  @override
  bool macVerify({
    required SecureKey key,
    required Uint8List message,
    required Uint8List tag,
  }) =>
      tag.length == _c.auth.bytes &&
      _c.auth.verify(tag: tag, message: message, key: key);

  @override
  Uint8List genericHash(Uint8List message, {required int outLen}) =>
      _c.genericHash(message: message, outLen: outLen);

  @override
  Future<SecureKey> pwhash({
    required String password,
    required Uint8List salt,
    required int outLen,
  }) {
    final s = _s; // capture the sodium instance, not `this` (holds _random)
    return s.runIsolated(
      (keys, pairs) => s.crypto.pwhash.callStr(
        outLen: outLen,
        password: password,
        salt: salt,
        opsLimit: s.crypto.pwhash.opsLimitInteractive,
        memLimit: s.crypto.pwhash.memLimitInteractive,
        alg: CryptoPwhashAlgorithm.argon2id13,
      ),
    );
  }

  @override
  Uint8List pad(Uint8List data, int blockSize) => _s.pad(data, blockSize);

  @override
  Uint8List? unpad(Uint8List data, int blockSize) {
    try {
      return _s.unpad(data, blockSize);
    } on SodiumException {
      return null; // invalid padding: the caller drops the message
    }
  }
}
