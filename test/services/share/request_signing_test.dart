import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/share/device_identity.dart';
import 'package:codecore/services/share/request_signing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DeviceIdentity a, b;
  setUpAll(() async {
    final da = Directory.systemTemp.createTempSync('sa'), db = Directory.systemTemp.createTempSync('sb');
    addTearDown(() {
      da.deleteSync(recursive: true);
      db.deleteSync(recursive: true);
    });
    a = await DeviceIdentity.loadOrCreate(da);
    b = await DeviceIdentity.loadOrCreate(db);
  });

  final body = utf8.encode('{"offer":1}');
  final t0 = DateTime(2026, 10, 19, 12);

  test('a signed request proves the fingerprint of the signer', () {
    final h = signRequest(a, 'post', '/offer/', body, now: t0);
    expect(verifyRequest(h, 'POST', '/offer/', body, now: t0), a.fingerprint);
    expect(verifyRequest(signRequest(b, 'POST', '/offer/', body, now: t0), 'POST', '/offer/', body, now: t0), b.fingerprint);
  });

  test('another body, method or path breaks it', () {
    final h = signRequest(a, 'POST', '/offer/', body, now: t0);
    expect(verifyRequest(h, 'POST', '/offer/', utf8.encode('{"offer":2}'), now: t0), isNull);
    expect(verifyRequest(h, 'GET', '/offer/', body, now: t0), isNull);
    expect(verifyRequest(h, 'POST', '/pair/confirm', body, now: t0), isNull);
  });

  test('a certificate with someone else\'s signature is not accepted as theirs', () {
    final h = signRequest(a, 'POST', '/x', body, now: t0);
    final forged = {...h, kCertHeader: signRequest(b, 'POST', '/x', body, now: t0)[kCertHeader]!};
    expect(verifyRequest(forged, 'POST', '/x', body, now: t0), isNull);
  });

  test('too old or from the future is refused; inside the window is fine', () {
    final h = signRequest(a, 'POST', '/x', body, now: t0);
    expect(verifyRequest(h, 'POST', '/x', body, now: t0.add(const Duration(seconds: 100))), a.fingerprint);
    expect(verifyRequest(h, 'POST', '/x', body, now: t0.add(const Duration(minutes: 3))), isNull);
    expect(verifyRequest(h, 'POST', '/x', body, now: t0.subtract(const Duration(minutes: 3))), isNull);
  });

  test('missing or malformed headers are just «not proven»', () {
    expect(verifyRequest({}, 'POST', '/x', body), isNull);
    final h = signRequest(a, 'POST', '/x', body, now: t0);
    expect(verifyRequest({...h, kSigHeader: 'zzzz'}, 'POST', '/x', body, now: t0), isNull);
    expect(verifyRequest({...h, kCertHeader: base64.encode(List.filled(50, 1))}, 'POST', '/x', body, now: t0), isNull);
    expect(verifyRequest({...h, kTimeHeader: 'soon'}, 'POST', '/x', body, now: t0), isNull);
  });
}
