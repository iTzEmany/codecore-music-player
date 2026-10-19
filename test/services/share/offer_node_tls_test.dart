import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/share/device_identity.dart';
import 'package:codecore/services/share/lan_client.dart';
import 'package:codecore/services/share/lan_server.dart';
import 'package:codecore/services/share/offers.dart';
import 'package:codecore/services/share/request_signing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

void main() {
  late Directory tmp;
  late DeviceIdentity idA, idB;
  late OfferService sender, receiver;
  late OfferNode senderNode, receiverNode, oldNode;
  late OfferService old;

  // Making a key pair is the slow part: once for the whole file.
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('tls-ids');
    addTearDown(() => dir.deleteSync(recursive: true));
    idA = await DeviceIdentity.loadOrCreate(Directory(p.join(dir.path, 'a')));
    idB = await DeviceIdentity.loadOrCreate(Directory(p.join(dir.path, 'b')));
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('tls');
    sender = OfferService(deviceId: 'a', deviceName: 'Sender', allowLoopback: true);
    receiver = OfferService(deviceId: 'b', deviceName: 'Receiver', allowLoopback: true);
    old = OfferService(deviceId: 'o', deviceName: 'Old phone', allowLoopback: true);
    senderNode = OfferNode(sender, allowLoopback: true, identity: idA);
    receiverNode = OfferNode(receiver, allowLoopback: true, identity: idB, secureRoutes: {
      '/whoami': (Request r) => Response.ok(callerFingerprint(r) ?? 'nobody'),
    }, extraRoutes: {
      '/jam': (Request r) => Response.ok('jam'),
    });
    oldNode = OfferNode(old, allowLoopback: true); // a version 2 device: no identity
    await senderNode.start();
    await receiverNode.start();
    await oldNode.start();
  });
  tearDown(() async {
    await senderNode.stop();
    await receiverNode.stop();
    await oldNode.stop();
    tmp.deleteSync(recursive: true);
  });

  ShareEntry entry() {
    final f = File(p.join(tmp.path, 'one.mp3'))..writeAsBytesSync(List.filled(100, 3));
    return ShareEntry(id: 1, path: f.path, title: 'Song', artist: 'Band', sizeBytes: 100, durationMs: 1000, ext: 'mp3');
  }

  Future<String> get(String url, {Map<String, String> headers = const {}}) async {
    final c = HttpClient()..badCertificateCallback = (_, _, _) => true;
    final req = await c.getUrl(Uri.parse(url));
    headers.forEach(req.headers.set);
    final res = await req.close();
    return res.transform(utf8.decoder).join();
  }

  test('hello: a node with identity announces version 3, its HTTPS port and fingerprint; v2 does not', () async {
    final c = LanClient();
    final info = await c.hello('127.0.0.1', receiverNode.port!);
    expect(info.tlsPort, receiverNode.tlsPort);
    expect(info.fingerprint, idB.fingerprint);
    expect(receiverNode.tlsPort, isNot(receiverNode.port));
    final v2 = await c.hello('127.0.0.1', oldNode.port!);
    expect(v2.tlsPort, isNull);
    expect(oldNode.tlsPort, isNull);
  });

  test('an offer over HTTPS arrives, carries the sender\'s HTTPS port, and a wrong pin refuses it', () async {
    final c = LanClient(identity: idA);
    final offer = sender.createOutgoing(toId: 'b', toName: 'Receiver', entries: [entry()]);
    await expectLater(
      c.sendOffer('127.0.0.1', receiverNode.port!, sender.offerPayload(offer, senderNode.port!, tlsPort: senderNode.tlsPort),
          tlsPort: receiverNode.tlsPort, pin: idA.fingerprint), // not B's fingerprint
      throwsA(isA<LanException>().having((e) => e.error, 'error', LanError.identityChanged)),
    );
    expect(receiver.incoming, isEmpty, reason: 'nothing was delivered to the wrong identity');

    await c.sendOffer('127.0.0.1', receiverNode.port!, sender.offerPayload(offer, senderNode.port!, tlsPort: senderNode.tlsPort),
        tlsPort: receiverNode.tlsPort, pin: idB.fingerprint);
    final inc = receiver.incoming[offer.offerId]!;
    expect(inc.fromTlsPort, senderNode.tlsPort);
    expect(inc.status, OfferStatus.pending);

    // The answer goes back over HTTPS too.
    await LanClient(identity: idB).offerAction('127.0.0.1', senderNode.port!, offer.offerId, 'decline', inc.token,
        tlsPort: inc.fromTlsPort, pin: idA.fingerprint);
    expect(offer.status, OfferStatus.declined);
  });

  test('a version 2 device still works in plain HTTP, both ways', () async {
    final c = LanClient(identity: idA);
    final offer = sender.createOutgoing(toId: 'o', toName: 'Old', entries: [entry()]);
    await c.sendOffer('127.0.0.1', oldNode.port!, sender.offerPayload(offer, senderNode.port!));
    expect(old.incoming[offer.offerId]!.fromTlsPort, isNull);

    final back = old.createOutgoing(toId: 'b', toName: 'Receiver', entries: [entry()]);
    await LanClient().sendOffer('127.0.0.1', receiverNode.port!, old.offerPayload(back, oldNode.port!));
    expect(receiver.incoming[back.offerId], isNotNull);
  });

  test('secure routes exist only over HTTPS; the Jam only over HTTP; a signature names the caller', () async {
    final https = 'https://127.0.0.1:${receiverNode.tlsPort}';
    final http = 'http://127.0.0.1:${receiverNode.port}';
    expect(await get('$https/whoami'), 'nobody', reason: 'unsigned');
    final signed = signRequest(idA, 'GET', '/whoami', const []);
    expect(await get('$https/whoami', headers: signed), idA.fingerprint);
    expect(await get('$https/jam'), isNot('jam'));
    expect(await get('$http/jam'), 'jam');
    expect(await get('$http/whoami'), isNot(idA.fingerprint));
    // A signature made for another path is not accepted.
    final other = signRequest(idA, 'GET', '/other', const []);
    expect(await get('$https/whoami', headers: other), 'nobody');
  });

  test('an offer knows who really signed it: the fingerprint over HTTPS, nothing over plain HTTP', () async {
    final signed = sender.createOutgoing(toId: 'b', toName: 'Receiver', entries: [entry()]);
    await LanClient(identity: idA).sendOffer('127.0.0.1', receiverNode.port!,
        sender.offerPayload(signed, senderNode.port!), tlsPort: receiverNode.tlsPort);
    expect(receiver.incoming[signed.offerId]!.callerFingerprint, idA.fingerprint);

    final plain = sender.createOutgoing(toId: 'b', toName: 'Receiver', entries: [entry()]);
    await LanClient(identity: idA).sendOffer('127.0.0.1', receiverNode.port!, sender.offerPayload(plain, senderNode.port!));
    expect(receiver.incoming[plain.offerId]!.callerFingerprint, isNull, reason: 'a claim of «I am a» proves nothing');
    expect(receiver.incoming[plain.offerId]!.trusted, isFalse);
  });
}
