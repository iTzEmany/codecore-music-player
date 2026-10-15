import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/jam/jam_cache.dart';
import 'package:codecore/services/jam/jam_guest.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

const host = 'host', guest = 'guest';
JamItem it(String o, {int dur = 1000}) =>
    JamItem(id: 0, ownerDeviceId: o, title: 't', ext: 'mp3', durationMs: dur);
JamState s0() => const JamState(hostDeviceId: host, outputDeviceId: host);
JamState ok(JamState s, JamCommand c, String f, {int now = 0}) {
  final r = applyCommand(s, c, from: f, nowMs: now);
  expect(r.isOk, true, reason: '${r.error}');
  return r.state!;
}

JamError? err(JamState s, JamCommand c, String f) =>
    applyCommand(s, c, from: f, nowMs: 0).error;

void main() {
  leaveTests();
  group('reducer edges', () {
    test('empty queue: play/seek/jump/remove/move are rejected', () {
      final s = s0();
      expect(err(s, const JamCommand.play(), host), JamError.invalid);
      expect(err(s, const JamCommand.seek(5), host), JamError.invalid);
      expect(err(s, const JamCommand.jump(1), host), JamError.notFound);
      expect(err(s, const JamCommand.remove(1), host), JamError.notFound);
      expect(err(s, const JamCommand.move(1, 0), host), JamError.notFound);
      // pause on empty is harmless
      expect(applyCommand(s, const JamCommand.pause(), from: guest, nowMs: 0).isOk, true);
    });

    test('removing the only item empties the queue and stops playing', () {
      var s = ok(s0(), JamCommand.add(it(host)), host);
      s = ok(s, const JamCommand.play(), host);
      s = ok(s, const JamCommand.remove(1), host);
      expect(s.items, isEmpty);
      expect(s.currentIndex, -1);
      expect(s.playing, false);
      // a new add becomes current again
      s = ok(s, JamCommand.add(it(guest)), guest);
      expect(s.currentIndex, 0);
    });

    test('host removes the current last item: index falls back', () {
      var s = ok(s0(), JamCommand.add(it(host)), host);
      s = ok(s, JamCommand.add(it(host)), host);
      s = ok(s, const JamCommand.jump(2), host);
      s = ok(s, const JamCommand.remove(2), host);
      expect(s.currentIndex, 0);
      expect(s.current!.id, 1);
    });

    test('moving the current item keeps it current', () {
      var s = s0();
      for (var i = 0; i < 4; i++) {
        s = ok(s, JamCommand.add(it(host)), host);
      }
      s = ok(s, const JamCommand.jump(2), host);
      s = ok(s, const JamCommand.move(2, 3), guest);
      expect(s.current!.id, 2);
      s = ok(s, const JamCommand.move(2, 0), guest);
      expect(s.current!.id, 2);
      expect(s.currentIndex, 0);
      // same position: no version bump
      final v = s.version;
      expect(ok(s, const JamCommand.move(2, 0), guest).version, v);
    });

    test('invalid values', () {
      var s = ok(s0(), JamCommand.add(it(host)), host);
      expect(err(s, const JamCommand.volume(1.5), host), JamError.invalid);
      expect(err(s, const JamCommand.volume(-0.1), host), JamError.invalid);
      expect(err(s, JamCommand.volume(double.nan), host), JamError.invalid);
      expect(err(s, const JamCommand.seek(-1), host), JamError.invalid);
      expect(err(s, const JamCommand.move(1, -1), host), JamError.invalid);
      s = ok(s, const JamCommand.volume(0.3), guest);
      expect(s.volume, 0.3);
    });

    test('guest cannot add as host, cannot end, host can name guest output', () {
      final s = ok(s0(), JamCommand.add(it(host)), host);
      expect(err(s, JamCommand.add(it(host)), guest), JamError.forbidden);
      expect(err(s, const JamCommand.end(), guest), JamError.forbidden);
      final o = ok(s, const JamCommand.setOutput(guest), host);
      expect(o.outputDeviceId, guest);
      // guest may only name itself or the host
      expect(err(s, const JamCommand.setOutput('x'), guest), JamError.invalid);
      expect(ok(o, const JamCommand.setOutput(host), guest).outputDeviceId, host);
    });

    test('position keeps flowing across output change and seek', () {
      var s = ok(s0(), JamCommand.add(it(host, dur: 100000)), host, now: 0);
      s = ok(s, const JamCommand.play(), host, now: 0);
      s = ok(s, const JamCommand.setOutput(guest), guest, now: 4000);
      expect(s.positionAtTime(6000), 6000);
      s = ok(s, const JamCommand.seek(50000), host, now: 6000);
      expect(s.positionAtTime(7000), 51000);
    });

    test('all commands refused after end', () {
      var s = ok(s0(), JamCommand.add(it(host)), host);
      s = ok(s, const JamCommand.end(), host);
      for (final c in [
        JamCommand.add(it(host)),
        const JamCommand.next(),
        const JamCommand.pause()
      ]) {
        expect(err(s, c, host), JamError.ended);
      }
    });

    test('untrusted JSON never throws', () {
      final junk = <Object?>[
        null, 1, 'x', [], {},
        {'cmd': 5}, {'cmd': 'add'}, {'cmd': 'add', 'item': 5},
        {'cmd': 'seek', 'pos': 'a'}, {'cmd': 'volume', 'volume': 'x'},
        {'cmd': 'setOutput', 'device': 'x' * 100},
        {'version': 1, 'items': List.filled(300, {}), 'host': 'h', 'output': 'h'},
      ];
      for (final j in junk) {
        expect(() => JamCommand.tryParse(j), returnsNormally);
        expect(() => JamState.tryParse(j), returnsNormally);
        expect(() => JamItem.tryParse(j), returnsNormally);
      }
      // oversized / control characters are clipped or refused
      expect(JamItem.tryParse({'id': 1, 'owner': 'o', 'title': 'x' * 300, 'ext': 'mp3'}), isNull);
      expect(JamItem.tryParse({'id': 1, 'owner': 'o', 'title': 'a\nb', 'ext': 'MP3'})!.title, 'a b');
      expect(JamItem.tryParse({'id': -1, 'owner': 'o', 'title': 'x', 'ext': 'mp3'}), isNull);
    });
  });

  group('host edges', () {
    late JamHost h;
    late Handler handler;
    var ip = '192.168.1.50';
    var now = DateTime(2026, 1, 1);

    Future<Response> call(String m, String path,
            {Object? body, Map<String, String>? headers, String? raw}) =>
        Future.sync(() => handler(Request(m, Uri.parse('http://x/$path'),
            body: raw ?? (body == null ? null : jsonEncode(body)),
            headers: headers)));

    Map<String, Object?> req({String id = 'g', int port = 4000, String tok = 'token-1234'}) =>
        {'fromId': id, 'fromName': 'N', 'port': port, 'token': tok};

    setUp(() {
      ip = '192.168.1.50';
      now = DateTime(2026, 1, 1);
      h = JamHost(deviceId: host, deviceName: 'PC', now: () => now,
          pollWait: const Duration(milliseconds: 50));
      handler = h.buildRouter(clientIp: (_) => ip).call;
    });

    test('malformed requests are refused', () async {
      expect((await call('POST', 'request', raw: 'not json')).statusCode, 400);
      expect((await call('POST', 'request', raw: '[1]')).statusCode, 400);
      for (final bad in [
        req(port: 0), req(port: 70000), req(tok: 'short'), req(id: ''),
        {...req(), 'fromName': 5},
      ]) {
        expect((await call('POST', 'request', body: bad)).statusCode, 400,
            reason: '$bad');
      }
      expect(h.requests, isEmpty);
    });

    test('rate limit per ip', () async {
      for (var i = 0; i < 5; i++) {
        final r = await call('POST', 'request', body: req(id: 'g$i'));
        expect(r.statusCode, anyOf(202, 409));
        for (final q in h.requests.values) {
          h.decline(q.id);
        }
      }
      expect((await call('POST', 'request', body: req(id: 'gx'))).statusCode, 429);
      now = now.add(const Duration(minutes: 2));
      expect((await call('POST', 'request', body: req(id: 'gy'))).statusCode, 202);
    });

    test('cancel by requester; accept after cancel fails', () async {
      await call('POST', 'request', body: req());
      final id = h.requests.keys.single;
      expect((await call('POST', 'request/$id/cancel')).statusCode, 401);
      expect((await call('POST', 'request/$id/cancel',
              headers: {'x-token': 'token-1234'}))
          .statusCode, 200);
      expect(h.accept(id), isNull);
    });

    test('second session after the first one is cleared', () async {
      await call('POST', 'request', body: req());
      h.accept(h.requests.keys.single);
      h.endSession();
      h.clearSession();
      expect((await call('POST', 'request', body: req(id: 'g2'))).statusCode, 202);
      expect(h.accept(h.requests.keys.last), isNotNull);
      expect(h.guest!.fromId, 'g2');
    });

    test('wrong session id / token on every host route', () async {
      await call('POST', 'request', body: req());
      h.accept(h.requests.keys.single);
      final sid = h.sessionId!, tok = h.sessionToken!;
      final good = {'x-jam-token': tok};
      expect((await call('GET', 'nope/state', headers: good)).statusCode, 401);
      expect((await call('POST', 'nope/cmd', body: {'cmd': 'play'}, headers: good)).statusCode, 401);
      expect((await call('GET', '$sid/file/1', headers: {'x-jam-token': 'a' * tok.length})).statusCode, 401);
      expect((await call('POST', '$sid/cmd', raw: '{bad', headers: good)).statusCode, 400);
    });

    test('file: bad item id, invalid range, missing file', () async {
      final dir = Directory.systemTemp.createTempSync('jamedge');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File('${dir.path}/a.mp3')..writeAsBytesSync(List.filled(10, 1));
      h.resolveFile = (i) async => i.ref == 'gone' ? '${dir.path}/zz.mp3' : f.path;
      await call('POST', 'request', body: req());
      h.accept(h.requests.keys.single);
      final sid = h.sessionId!;
      final a = {'x-jam-token': h.sessionToken!};
      h.apply(JamCommand.add(JamItem(id: 0, ownerDeviceId: host, title: 'a', ext: 'mp3', ref: 'ok')));
      h.apply(JamCommand.add(JamItem(id: 0, ownerDeviceId: host, title: 'b', ext: 'mp3', ref: 'gone')));
      expect((await call('GET', '$sid/file/abc', headers: a)).statusCode, 404);
      expect((await call('GET', '$sid/file/1', headers: {...a, 'range': 'bytes=50-60'})).statusCode, 416);
      expect((await call('GET', '$sid/file/2', headers: a)).statusCode, 404);
      // removed from the queue → no longer served
      h.apply(const JamCommand.remove(1));
      expect((await call('GET', '$sid/file/1', headers: a)).statusCode, 404);
    });
  });

  group('guest / cache edges', () {
    test('unreachable host and refused connection', () async {
      final local = JamHost(deviceId: guest, deviceName: 'g');
      final g = JamGuest(local: local, requestPoll: const Duration(milliseconds: 10));
      final out = await g.join(
          host: '127.0.0.1', port: 1, ownDeviceId: guest, ownName: 'g', ownPort: 2);
      expect(out, JamJoinOutcome.unreachable);
      expect((await g.send(const JamCommand.play())).error, JamError.ended);
      await g.dispose();
    });

    test('cache: concurrent fetch shares one download', () async {
      final srv = await HttpServer.bind('127.0.0.1', 0);
      var hits = 0;
      srv.listen((r) async {
        hits++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        r.response.add([1, 2, 3]);
        await r.response.close();
      });
      final dir = Directory.systemTemp.createTempSync('jc');
      addTearDown(() async {
        await srv.close(force: true);
        dir.deleteSync(recursive: true);
      });
      final c = JamCache(Directory('${dir.path}/c'));
      const item = JamItem(id: 9, ownerDeviceId: 'p', title: 't', ext: 'mp3');
      final u = Uri.parse('http://127.0.0.1:${srv.port}/x');
      final r = await Future.wait([c.fetch(item, u, {}), c.fetch(item, u, {})]);
      expect(r[0]!.path, r[1]!.path);
      expect(hits, 1);
    });
  });
}

void leaveTests() {
  test('guest leave ends the session; stale guest is detected', () async {
    var now = DateTime(2026, 1, 1);
    final h = JamHost(deviceId: 'host', deviceName: 'PC', now: () => now);
    final handler = h.buildRouter(clientIp: (_) => '192.168.1.5').call;
    Future<Response> call(String m, String p, {Object? body, Map<String, String>? hd}) =>
        Future.sync(() => handler(Request(m, Uri.parse('http://x/$p'),
            body: body == null ? null : jsonEncode(body), headers: hd)));
    await call('POST', 'request', body: {
      'fromId': 'g', 'fromName': 'G', 'port': 4000, 'token': 'token-1234'
    });
    h.accept(h.requests.keys.single);
    expect(h.guestStale(const Duration(seconds: 75)), false);
    now = now.add(const Duration(seconds: 80));
    expect(h.guestStale(const Duration(seconds: 75)), true);
    final auth = {'x-jam-token': h.sessionToken!};
    // any authenticated call refreshes the liveness
    await call('GET', '${h.sessionId}/state?since=-1', hd: auth);
    expect(h.guestStale(const Duration(seconds: 75)), false);
    expect((await call('POST', '${h.sessionId}/leave')).statusCode, 401);
    expect((await call('POST', '${h.sessionId}/leave', hd: auth)).statusCode, 200);
    expect(h.state!.ended, true);
  });
}
