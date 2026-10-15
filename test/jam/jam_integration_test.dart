import 'dart:io';

import 'package:codecore/services/jam/jam_guest.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/share/offers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late JamHost hostJam, guestJam;
  late OfferNode hostNode, guestNode;
  late int hostPort, guestPort;
  late JamGuest guest;
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('jam_int');
    hostJam = JamHost(
        deviceId: 'host', deviceName: 'PC', allowLoopback: true,
        pollWait: const Duration(seconds: 2));
    guestJam = JamHost(
        deviceId: 'guest', deviceName: 'Phone', allowLoopback: true,
        pollWait: const Duration(seconds: 2));
    hostNode = OfferNode(
        OfferService(deviceId: 'host', deviceName: 'PC', allowLoopback: true),
        allowLoopback: true,
        extraRoutes: {'/jam': hostJam.buildRouter().call});
    guestNode = OfferNode(
        OfferService(deviceId: 'guest', deviceName: 'Phone', allowLoopback: true),
        allowLoopback: true,
        extraRoutes: {'/jam': guestJam.buildRouter().call});
    hostPort = await hostNode.start();
    guestPort = await guestNode.start();
    guest = JamGuest(
        local: guestJam,
        requestPoll: const Duration(milliseconds: 50),
        backoff: const Duration(milliseconds: 20),
        maxFailures: 3);
    hostJam.onRequest = (r) => hostJam.accept(r.id);
  });

  tearDown(() async {
    await guest.dispose();
    await hostNode.stop();
    await guestNode.stop();
    dir.deleteSync(recursive: true);
  });

  Future<void> join() async {
    final o = await guest.join(
        host: '127.0.0.1',
        port: hostPort,
        ownDeviceId: 'guest',
        ownName: 'Phone',
        ownPort: guestPort);
    expect(o, JamJoinOutcome.accepted);
  }

  test('guest and host edit the same queue, guest cannot jump', () async {
    await join();
    expect(guest.state!.hostDeviceId, 'host');

    final r = await guest.send(const JamCommand.add(JamItem(
        id: 0, ownerDeviceId: 'guest', title: 'G', ext: 'mp3', ref: '1')));
    expect(r.isOk, true);
    expect(hostJam.state!.items.single.title, 'G');

    hostJam.apply(const JamCommand.add(
        JamItem(id: 0, ownerDeviceId: 'host', title: 'H', ext: 'flac')));
    await guest.states
        .firstWhere((s) => s.items.length == 2)
        .timeout(const Duration(seconds: 5));
    expect(guest.state!.items.map((i) => i.title), ['G', 'H']);

    final j = await guest.send(const JamCommand.jump(2));
    expect(j.error, JamError.forbidden);
    final rm = await guest.send(const JamCommand.remove(2));
    expect(rm.error, JamError.forbidden);
    final mv = await guest.send(const JamCommand.move(2, 0));
    expect(mv.isOk, true);
    expect(hostJam.state!.items.first.title, 'H');
  });

  test('host serves its file to the guest, guest serves its own', () async {
    final hf = File('${dir.path}/h.mp3')..writeAsBytesSync([1, 2, 3, 4]);
    final gf = File('${dir.path}/g.mp3')..writeAsBytesSync([9, 9]);
    hostJam.resolveFile = (i) async => hf.path;
    guestJam.resolveFile = (i) async => gf.path;
    await join();
    await guest.send(const JamCommand.add(JamItem(
        id: 0, ownerDeviceId: 'guest', title: 'G', ext: 'mp3', ref: '1')));
    hostJam.apply(const JamCommand.add(
        JamItem(id: 0, ownerDeviceId: 'host', title: 'H', ext: 'mp3')));
    await guest.states
        .firstWhere((s) => s.items.length == 2)
        .timeout(const Duration(seconds: 5));

    final dio = Dio(BaseOptions(responseType: ResponseType.bytes));
    final h = {'x-jam-file': guest.fileToken};
    final fromHost = await dio.get<List<int>>(
        'http://127.0.0.1:$hostPort/jam/${guest.sessionId}/file/2',
        options: Options(headers: h));
    expect(fromHost.data, [1, 2, 3, 4]);
    // the host fetches the guest's file with the same session token
    final fromGuest = await dio.get<List<int>>(
        'http://127.0.0.1:$guestPort/jam/${guest.sessionId}/file/1',
        options: Options(headers: {'x-jam-file': hostJam.fileToken}));
    expect(fromGuest.data, [9, 9]);
  });

  test('declined and ended', () async {
    hostJam.onRequest = (r) => hostJam.decline(r.id);
    final o = await guest.join(
        host: '127.0.0.1', port: hostPort, ownDeviceId: 'guest',
        ownName: 'Phone', ownPort: guestPort);
    expect(o, JamJoinOutcome.declined);

    hostJam.onRequest = (r) => hostJam.accept(r.id);
    await join();
    final ended = guest.states.firstWhere((s) => s.ended);
    hostJam.endSession();
    expect((await ended.timeout(const Duration(seconds: 5))).ended, true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(guest.active, false);
  });

  test('host disappearing marks the session lost', () async {
    await join();
    final lost = guest.lost.first;
    await hostNode.stop();
    await lost.timeout(const Duration(seconds: 15));
    expect(guest.active, false);
  });

  test('three devices: a guest accepts a newcomer on behalf of the host',
      () async {
    await join();
    final jamB = JamHost(
        deviceId: 'guestB', deviceName: 'Tablet', allowLoopback: true,
        pollWait: const Duration(seconds: 2));
    final nodeB = OfferNode(
        OfferService(deviceId: 'guestB', deviceName: 'Tablet', allowLoopback: true),
        allowLoopback: true,
        extraRoutes: {'/jam': jamB.buildRouter().call});
    final portB = await nodeB.start();
    final guestB = JamGuest(
        local: jamB,
        requestPoll: const Duration(milliseconds: 50),
        backoff: const Duration(milliseconds: 20),
        maxFailures: 3);
    addTearDown(() async {
      await guestB.dispose();
      await nodeB.stop();
    });
    // The first guest answers for the host.
    guestJam.onRequest = (r) => guest.invite(r);

    final o = await guestB.join(
        host: '127.0.0.1',
        port: guestPort, // asks the guest, not the host
        ownDeviceId: 'guestB',
        ownName: 'Tablet',
        ownPort: portB);
    expect(o, JamJoinOutcome.accepted);
    expect(hostJam.memberIds, containsAll(['guest', 'guestB']));
    expect(guestB.hostBase, 'http://127.0.0.1:$hostPort/jam');

    // everyone sees the same roster
    await guestB.states
        .firstWhere((s) => s.participants.length == 3)
        .timeout(const Duration(seconds: 5), onTimeout: () => guestB.state!);
    expect(guestB.state!.participants.map((p) => p.name),
        containsAll(['PC', 'Phone', 'Tablet']));

    // B adds a track it owns; the original guest can fetch it from B
    final gf = File('${dir.path}/b.mp3')..writeAsBytesSync([5, 6, 7]);
    jamB.resolveFile = (i) async => gf.path;
    final r = await guestB.send(const JamCommand.add(JamItem(
        id: 0, ownerDeviceId: 'guestB', title: 'B', ext: 'mp3', ref: '1')));
    expect(r.isOk, true);
    await guest.states
        .firstWhere((s) => s.items.length == 1)
        .timeout(const Duration(seconds: 5));
    final owner = guest.state!.participant('guestB')!;
    final dio = Dio(BaseOptions(responseType: ResponseType.bytes));
    final got = await dio.get<List<int>>(
        'http://${owner.host}:${owner.port}/jam/${guest.sessionId}/file/1',
        options: Options(headers: {'x-jam-file': guest.fileToken}));
    expect(got.data, [5, 6, 7]);

    // B leaves: its track vanishes, the others stay
    await guestB.leave();
    await guest.states
        .firstWhere((s) => s.items.isEmpty && s.participants.length == 2)
        .timeout(const Duration(seconds: 5));
    expect(hostJam.state!.ended, false);
  });
}
