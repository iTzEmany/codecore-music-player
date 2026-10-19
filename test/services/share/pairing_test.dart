import 'dart:io';

import 'package:codecore/services/share/device_identity.dart';
import 'package:codecore/services/share/lan_client.dart';
import 'package:codecore/services/share/offers.dart';
import 'package:codecore/services/share/pairing.dart';
import 'package:codecore/services/share/pairing_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late DeviceIdentity idA, idB;
  late OfferNode nodeB;
  late PairingServer server;
  late PairingClient client;
  late List<PairRequest> shown, paired;
  var clock = DateTime(2026, 10, 19, 12);

  // Making a key pair is the slow part: once for the whole file.
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('pair-ids');
    addTearDown(() => dir.deleteSync(recursive: true));
    idA = await DeviceIdentity.loadOrCreate(Directory(p.join(dir.path, 'a')));
    idB = await DeviceIdentity.loadOrCreate(Directory(p.join(dir.path, 'b')));
  });

  setUp(() async {
    clock = DateTime(2026, 10, 19, 12);
    shown = [];
    paired = [];
    server = PairingServer(ownFingerprint: idB.fingerprint, ownId: 'dev-b', ownName: 'PC di B', now: () => clock)
      ..onRequest = shown.add
      ..onPaired = paired.add;
    nodeB = OfferNode(OfferService(deviceId: 'dev-b', deviceName: 'PC di B', allowLoopback: true),
        allowLoopback: true, identity: idB, secureRoutes: {'/pair': server.buildRouter().call});
    await nodeB.start();
    client = PairingClient(LanClient(identity: idA), idA, pollEvery: const Duration(milliseconds: 20));
  });
  tearDown(() => nodeB.stop());

  Future<PairedPeer> run(Future<String?> Function(String, int?) askPin) =>
      client.pair('127.0.0.1', nodeB.tlsPort!, ownId: 'dev-a', ownName: 'Telefono di A', askPin: askPin);

  test('proof binds the PIN to both fingerprints', () {
    final ok = pairingProof('123456', 'AA', 'BB');
    expect(ok, pairingProof('123456', 'AA', 'BB'));
    expect(ok, isNot(pairingProof('123457', 'AA', 'BB')));
    expect(ok, isNot(pairingProof('123456', 'AA', 'CC')), reason: 'a man in the middle shows another fingerprint');
    expect(constantTimeEquals('abc', 'abc'), isTrue);
    expect(constantTimeEquals('abc', 'abd'), isFalse);
    expect(constantTimeEquals('abc', 'abcd'), isFalse);
  });

  test('right PIN and the person confirming: both sides learn each other\'s fingerprint', () async {
    final future = run((seenFp, left) async {
      expect(seenFp, idB.fingerprint, reason: 'the fingerprint of the certificate it really talked to');
      expect(left, isNull);
      final req = shown.single;
      expect(req.fingerprint, idA.fingerprint, reason: 'proven by the signature, shown on the other screen');
      expect(req.pin, matches(RegExp(r'^\d{6}$')));
      // The person at B taps «Conferma» a moment after A sends the PIN.
      Future<void>.delayed(const Duration(milliseconds: 100), () => server.accept(req.id));
      return req.pin;
    });
    final peer = await future;
    expect((peer.id, peer.name, peer.fingerprint), ('dev-b', 'PC di B', idB.fingerprint));
    expect(paired.single.fingerprint, idA.fingerprint);
    expect(paired.single.deviceId, 'dev-a');
  });

  test('without the confirmation of the person at B nothing is paired', () async {
    final future = run((_, _) async => shown.single.pin);
    // Nobody confirms; the person says no.
    Future<void>.delayed(const Duration(milliseconds: 150), () => server.reject(shown.single.id));
    await expectLater(future, throwsA(isA<PairingException>().having((e) => e.error, 'error', PairingError.rejected)));
    expect(paired, isEmpty);
    expect(server.accept(shown.single.id), isFalse);
  });

  test('a wrong PIN can be retried; five wrong ones block the request', () async {
    var tries = 0;
    final lefts = <int?>[];
    await expectLater(
      run((_, left) async {
        lefts.add(left);
        tries++;
        return '000000'; // (a one-in-a-million chance it is right)
      }),
      throwsA(isA<PairingException>().having((e) => e.error, 'error', PairingError.blocked)),
    );
    expect(tries, 5);
    expect(lefts, [null, 4, 3, 2, 1]);
    expect(paired, isEmpty);
  });

  test('a wrong PIN then the right one still pairs', () async {
    var asked = 0;
    final peer = await run((_, left) async {
      asked++;
      final req = shown.single;
      if (asked == 1) return req.pin == '999999' ? '111111' : '999999';
      Future<void>.delayed(const Duration(milliseconds: 50), () => server.accept(req.id));
      return req.pin;
    });
    expect(asked, 2);
    expect(peer.fingerprint, idB.fingerprint);
  });

  test('the user giving up (no PIN) cancels; accepting before the PIN is proven does nothing', () async {
    await expectLater(run((_, _) async => null), throwsA(isA<PairingException>().having((e) => e.error, 'error', PairingError.cancelled)));
    expect(server.accept(shown.single.id), isFalse, reason: 'the PIN was never proven');
    expect(paired, isEmpty);
  });

  test('an expired request is refused', () async {
    final future = run((_, _) async {
      clock = clock.add(kPairingTtl + const Duration(seconds: 1));
      return shown.single.pin;
    });
    await expectLater(future, throwsA(isA<PairingException>().having((e) => e.error, 'error', PairingError.expired)));
  });

  test('requests from a caller that does not sign are refused; too many requests are limited', () async {
    final unsigned = LanClient(); // no identity: no signature
    final r = await unsigned.securePost('127.0.0.1', nodeB.tlsPort!, '/pair/request', {'id': 'x', 'name': 'x'});
    expect(r.status, 401);
    expect(shown, isEmpty);

    final signed = LanClient(identity: idA);
    final statuses = <int>[];
    for (var i = 0; i < kPairingRequestsPerMinute + 1; i++) {
      statuses.add((await signed.securePost('127.0.0.1', nodeB.tlsPort!, '/pair/request', {'id': 'a', 'name': 'A'})).status);
    }
    expect(statuses, [202, 202, 202, 429]);
  });

  test('another device cannot answer for a request it did not make', () async {
    final signedA = LanClient(identity: idA);
    final reqId = (await signedA.securePost('127.0.0.1', nodeB.tlsPort!, '/pair/request', {'id': 'a', 'name': 'A'})).json!['requestId'];
    final other = Directory.systemTemp.createTempSync('pair-c');
    addTearDown(() => other.deleteSync(recursive: true));
    final idC = await DeviceIdentity.loadOrCreate(other);
    final r = await LanClient(identity: idC).securePost('127.0.0.1', nodeB.tlsPort!, '/pair/confirm',
        {'requestId': reqId, 'proof': pairingProof(shown.single.pin, idC.fingerprint, idB.fingerprint)});
    expect(r.status, 404);
  });
}
