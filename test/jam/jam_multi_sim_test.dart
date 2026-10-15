import 'dart:async';
import 'dart:io';

import 'package:codecore/services/jam/jam_guest.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/share/offers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// One simulated device: its own HTTP node, Jam routes and guest client.
class Dev {
  Dev(String id)
      : id = id,
        jam = JamHost(
            deviceId: id,
            deviceName: id,
            allowLoopback: true,
            pollWait: const Duration(seconds: 1)) {
    node = OfferNode(
        OfferService(deviceId: id, deviceName: id, allowLoopback: true),
        allowLoopback: true,
        extraRoutes: {'/jam': jam.buildRouter().call});
    guest = JamGuest(
        local: jam,
        requestPoll: const Duration(milliseconds: 30),
        backoff: const Duration(milliseconds: 20),
        maxFailures: 3,
        lostAfter: const Duration(seconds: 2));
  }

  final String id;
  final JamHost jam;
  late final OfferNode node;
  late final JamGuest guest;
  late final int port;

  Future<void> start() async => port = await node.start();

  Future<JamJoinOutcome> joinThrough(Dev other) => guest.join(
      host: '127.0.0.1',
      port: other.port,
      ownDeviceId: id,
      ownName: id,
      ownPort: port,
      timeout: const Duration(seconds: 5));

  Future<void> stop() async {
    await guest.dispose();
    await node.stop();
  }
}

void main() {
  late List<Dev> devs;
  late Directory dir;

  Future<Dev> make(String id) async {
    final d = Dev(id);
    await d.start();
    devs.add(d);
    return d;
  }

  setUp(() {
    devs = [];
    dir = Directory.systemTemp.createTempSync('jamsim');
  });

  tearDown(() async {
    for (final d in devs) {
      await d.stop();
    }
    dir.deleteSync(recursive: true);
  });

  /// [via] accepts for the host when it is a guest, else the host itself does.
  void autoAccept(Dev d, {Dev? hostOf}) {
    d.jam.onRequest = (r) {
      if (d.jam.isGuest) {
        unawaited(d.guest.invite(r));
      } else {
        d.jam.accept(r.id);
      }
    };
  }

  test('five devices fill the session, a sixth is turned away', () async {
    final host = await make('host');
    autoAccept(host);
    final guests = [for (var i = 1; i <= 4; i++) await make('g$i')];
    for (final g in guests) {
      expect(await g.joinThrough(host), JamJoinOutcome.accepted, reason: g.id);
    }
    expect(host.jam.state!.participants.length, 5);

    final late = await make('late');
    expect(await late.joinThrough(host), JamJoinOutcome.busy);

    // every guest converges on the same roster
    for (final g in guests) {
      final s = await g.guest.states
          .firstWhere((s) => s.participants.length == 5)
          .timeout(const Duration(seconds: 5), onTimeout: () => g.guest.state!);
      expect(s.participants.length, 5, reason: g.id);
    }
  });

  test('items from every guest are served by their owners to each other',
      () async {
    final host = await make('host');
    autoAccept(host);
    final a = await make('a');
    final b = await make('b');
    final c = await make('c');
    for (final g in [a, b, c]) {
      expect(await g.joinThrough(host), JamJoinOutcome.accepted);
    }
    final files = <String, File>{};
    for (final d in [host, a, b, c]) {
      final f = File('${dir.path}/${d.id}.mp3')
        ..writeAsBytesSync(d.id.codeUnits);
      files[d.id] = f;
      d.jam.resolveFile = (_) async => f.path;
    }
    // everybody queues one track
    host.jam.apply(const JamCommand.add(
        JamItem(id: 0, ownerDeviceId: 'host', title: 'h', ext: 'mp3')));
    for (final g in [a, b, c]) {
      final r = await g.guest.send(JamCommand.add(JamItem(
          id: 0, ownerDeviceId: g.id, title: g.id, ext: 'mp3', ref: g.id)));
      expect(r.isOk, true);
    }
    final s = host.jam.state!;
    expect(s.items.length, 4);

    // device c downloads every item from its owner, as a real output would
    final dio = Dio(BaseOptions(responseType: ResponseType.bytes));
    final sid = c.guest.sessionId;
    for (final it in s.items) {
      final owner = s.participant(it.ownerDeviceId)!;
      final port = owner.id == 'host' ? host.port : owner.port;
      final r = await dio.get<List<int>>(
          'http://127.0.0.1:$port/jam/$sid/file/${it.id}',
          options: Options(headers: {jamFileHeader: c.guest.fileToken}));
      expect(String.fromCharCodes(r.data!), owner.id, reason: it.title);
    }
    // the identity token must not open somebody else's files
    expect(
        () => dio.get<List<int>>(
            'http://127.0.0.1:${a.port}/jam/$sid/file/2',
            options: Options(headers: {jamFileHeader: c.guest.sessionToken})),
        throwsA(isA<DioException>()));
  });

  test('the guest that invited another one can drop without ending it',
      () async {
    final host = await make('host');
    autoAccept(host);
    final a = await make('a');
    autoAccept(a);
    final b = await make('b');
    expect(await a.joinThrough(host), JamJoinOutcome.accepted);
    // b is let in by a, on behalf of the host
    expect(await b.joinThrough(a), JamJoinOutcome.accepted);
    expect(host.jam.memberIds, ['a', 'b']);
    expect(b.guest.hostBase, 'http://127.0.0.1:${host.port}/jam');

    // a vanishes (process killed): the host keeps b and the session
    await a.stop();
    // b keeps polling (<=1 s apart), a does not: only a goes stale
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    final dropped = host.jam.dropStale(const Duration(milliseconds: 1800));
    expect(dropped, contains('a'));
    expect(host.jam.state!.ended, false);
    expect(host.jam.memberIds, ['b']);

    // b still works against the host
    final r = await b.guest.send(const JamCommand.volume(0.4));
    expect(r.isOk, true);
    expect(host.jam.state!.volume, 0.4);
  });

  test('host ending reaches every guest; token reuse is rejected', () async {
    final host = await make('host');
    autoAccept(host);
    final a = await make('a');
    final b = await make('b');
    await a.joinThrough(host);
    await b.joinThrough(host);
    final ended = [
      for (final g in [a, b])
        g.guest.states.firstWhere((s) => s.ended).timeout(const Duration(seconds: 5))
    ];
    // a cannot act as b: commands are attributed by token, not by claim
    final r = await a.guest.send(JamCommand.add(const JamItem(
        id: 0, ownerDeviceId: 'b', title: 'x', ext: 'mp3')));
    expect(r.error, JamError.forbidden);

    host.jam.endSession();
    await Future.wait(ended);
    expect(host.jam.state!.ended, true);
  });

  test('guest of a vanished host gives up within the timeout', () async {
    final host = await make('host');
    autoAccept(host);
    final a = await make('a');
    await a.joinThrough(host);
    final lost = a.guest.lost.first;
    await host.node.stop();
    await lost.timeout(const Duration(seconds: 15));
    expect(a.guest.active, false);
  });
}
