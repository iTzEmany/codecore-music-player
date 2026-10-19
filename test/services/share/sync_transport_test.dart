import 'dart:io';

import 'package:codecore/services/backup/user_data.dart';
import 'package:codecore/services/share/device_identity.dart';
import 'package:codecore/services/share/lan_client.dart';
import 'package:codecore/services/share/offers.dart';
import 'package:codecore/services/share/playlist_sync.dart';
import 'package:codecore/services/share/sync_client.dart';
import 'package:codecore/services/share/sync_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late DeviceIdentity idA, idB, idC;
  late OfferNode nodeB;
  late Set<String> trusted;
  late List<(String, TrackRequest)> wanted;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('sync');
    Future<DeviceIdentity> make(String n) => DeviceIdentity.loadOrCreate(Directory(p.join(tmp.path, n))..createSync());
    idA = await make('a');
    idB = await make('b');
    idC = await make('c');
    trusted = {idA.fingerprint};
    wanted = [];
    nodeB = OfferNode(OfferService(deviceId: 'b', deviceName: 'B', allowLoopback: true),
        allowLoopback: true,
        identity: idB,
        secureRoutes: {
          '/sync': buildSyncRouter(
            export: () async => [
              const RemotePlaylist(uuid: 'u1', name: 'Mix', createdAt: 1, updatedAt: 5, items: [TrackRef(title: 'x', relPath: 'x.mp3')]),
            ],
            isTrusted: trusted.contains,
            onWant: (host, fp, req) async {
              wanted.add((host, req));
              return req.refs.length;
            },
          ).call,
        });
    await nodeB.start();
  });
  tearDown(() async {
    await nodeB.stop();
    tmp.deleteSync(recursive: true);
  });

  SyncClient client(DeviceIdentity id) => SyncClient(LanClient(identity: id));

  test('a trusted device reads the playlists in the portable format', () async {
    final list = await client(idA).playlists('127.0.0.1', nodeB.tlsPort!, pin: idB.fingerprint);
    expect(list.single.uuid, 'u1');
    expect(list.single.updatedAt, 5);
    expect(list.single.items.single.relPath, 'x.mp3');
  });

  test('an untrusted device, or an unsigned one, is refused', () async {
    await expectLater(client(idC).playlists('127.0.0.1', nodeB.tlsPort!, pin: idB.fingerprint),
        throwsA(isA<SyncException>().having((e) => e.error, 'error', SyncError.notTrusted)));
    await expectLater(SyncClient(LanClient()).playlists('127.0.0.1', nodeB.tlsPort!, pin: idB.fingerprint),
        throwsA(isA<SyncException>().having((e) => e.error, 'error', SyncError.notTrusted)));
  });

  test('a changed identity is reported, not followed', () async {
    await expectLater(client(idA).playlists('127.0.0.1', nodeB.tlsPort!, pin: idC.fingerprint),
        throwsA(isA<SyncException>().having((e) => e.error, 'error', SyncError.identityChanged)));
  });

  test('«want» reaches the other device with the caller\'s address and ports', () async {
    final n = await client(idA).want('127.0.0.1', nodeB.tlsPort!, [const TrackRef(title: 'a'), const TrackRef(title: 'b')],
        pin: idB.fingerprint, port: 4001, tlsPortHere: 4002);
    expect(n, 2);
    final (host, req) = wanted.single;
    expect(host, '127.0.0.1');
    expect((req.port, req.tlsPort), (4001, 4002));
    expect([for (final r in req.refs) r.title], ['a', 'b']);
    await expectLater(client(idC).want('127.0.0.1', nodeB.tlsPort!, [const TrackRef(title: 'a')], pin: idB.fingerprint, port: 1),
        throwsA(isA<SyncException>()));
    expect(wanted, hasLength(1));
  });
}
