import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/share/device_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('ident'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('made once, read back the same; the fingerprint is SHA-256 of the DER', () async {
    final a = await DeviceIdentity.loadOrCreate(dir);
    expect(a.regenerated, isFalse);
    expect(a.fingerprint, matches(RegExp(r'^[0-9A-F]{64}$')));
    final b = await DeviceIdentity.loadOrCreate(dir);
    expect(b.fingerprint, a.fingerprint);
    expect(b.certPem, a.certPem);
    expect(b.regenerated, isFalse);
    expect(DeviceIdentity.fingerprintOfDer(DeviceIdentity.derFromPem(a.certPem)), a.fingerprint);
  });

  test('two devices have different identities', () async {
    final other = Directory.systemTemp.createTempSync('ident2');
    addTearDown(() => other.deleteSync(recursive: true));
    expect((await DeviceIdentity.loadOrCreate(dir)).fingerprint,
        isNot((await DeviceIdentity.loadOrCreate(other)).fingerprint));
  });

  test('a damaged file gives a new identity and says so', () async {
    final old = await DeviceIdentity.loadOrCreate(dir);
    File(p.join(dir.path, 'identity', 'key.pem')).writeAsStringSync('garbage');
    final fresh = await DeviceIdentity.loadOrCreate(dir);
    expect(fresh.regenerated, isTrue);
    expect(fresh.fingerprint, isNot(old.fingerprint));
    expect((await DeviceIdentity.loadOrCreate(dir)).regenerated, isFalse, reason: 'the new pair is now the stored one');
  });

  test('a certificate with another device\'s key is rejected as a pair', () async {
    final other = Directory.systemTemp.createTempSync('ident3');
    addTearDown(() => other.deleteSync(recursive: true));
    final a = await DeviceIdentity.loadOrCreate(dir);
    final b = await DeviceIdentity.loadOrCreate(other);
    File(p.join(dir.path, 'identity', 'key.pem')).writeAsStringSync(b.keyPem);
    final r = await DeviceIdentity.loadOrCreate(dir);
    expect(r.regenerated, isTrue);
    expect(r.fingerprint, isNot(a.fingerprint));
  });

  test('the context serves HTTPS and a client can check the fingerprint', () async {
    final id = await DeviceIdentity.loadOrCreate(dir);
    final server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, id.context());
    addTearDown(() => server.close(force: true));
    server.listen((r) {
      r.response.write('hi');
      r.response.close();
    });

    String? seen;
    final good = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        seen = DeviceIdentity.fingerprintOfDer(cert.der);
        return seen == id.fingerprint;
      };
    final res = await (await good.getUrl(Uri.parse('https://127.0.0.1:${server.port}/'))).close();
    expect(await res.transform(utf8.decoder).join(), 'hi');
    expect(seen, id.fingerprint);

    final wrong = HttpClient()..badCertificateCallback = (cert, host, port) => false;
    await expectLater(wrong.getUrl(Uri.parse('https://127.0.0.1:${server.port}/')).then((r) => r.close()), throwsA(isA<HandshakeException>()));
  });
}
