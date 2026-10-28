import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/jam/jam_host.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/share/track_meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

void main() {
  late JamHost host;
  late Handler h;
  var now = DateTime(2026, 1, 1, 12);
  final seen = <JamRequest>[];

  Future<Response> call(String method, String path,
      {Object? body, Map<String, String>? headers}) {
    return Future.sync(() => h(Request(
          method,
          Uri.parse('http://localhost/$path'),
          body: body == null ? null : jsonEncode(body),
          headers: headers,
        )));
  }

  Future<Map<String, dynamic>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;

  Map<String, Object?> reqBody({String id = 'guest'}) => {
        'fromId': id,
        'fromName': 'Phone',
        'port': 4000,
        'token': 'reqtoken-123',
      };

  Future<({String sid, String token})> startSession() async {
    final r = await call('POST', 'request', body: reqBody());
    final rid = (await json(r))['requestId'] as String;
    expect(host.accept(rid), isNotNull);
    final st = await json(await call('GET', 'request/$rid',
        headers: {'x-token': 'reqtoken-123'}));
    expect(st['status'], 'accepted');
    return (sid: st['sessionId'] as String, token: st['token'] as String);
  }

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    seen.clear();
    host = JamHost(
        deviceId: 'host',
        deviceName: 'PC',
        now: () => now,
        pollWait: const Duration(milliseconds: 100))
      ..onRequest = seen.add;
    final router = host.buildRouter(clientIp: (_) => '192.168.1.50');
    h = router.call;
  });

  test('request is pending until the user accepts', () async {
    final r = await call('POST', 'request', body: reqBody());
    expect(r.statusCode, 202);
    expect(seen, hasLength(1));
    final rid = seen.single.id;
    var st = await json(await call('GET', 'request/$rid',
        headers: {'x-token': 'reqtoken-123'}));
    expect(st['status'], 'pending');
    expect(st.containsKey('token'), false);
    expect((await call('GET', 'request/$rid', headers: {'x-token': 'nope'}))
        .statusCode, 401);
    // a second request while one is pending
    expect((await call('POST', 'request', body: reqBody(id: 'other')))
        .statusCode, 409);
    host.decline(rid);
    st = await json(await call('GET', 'request/$rid',
        headers: {'x-token': 'reqtoken-123'}));
    expect(st['status'], 'declined');
  });

  test('request expires and refuses non-local', () async {
    await call('POST', 'request', body: reqBody());
    now = now.add(const Duration(minutes: 6));
    expect(host.accept(seen.single.id), isNull);
    final public = JamHost(deviceId: 'h', deviceName: 'h')
        .buildRouter(clientIp: (_) => '8.8.8.8');
    final r = await public.call(Request('POST', Uri.parse('http://x/request'),
        body: jsonEncode(reqBody())));
    expect(r.statusCode, 403);
  });

  test('state, commands, permissions and auth', () async {
    final s = await startSession();
    final auth = {'x-jam-token': s.token};
    expect((await call('GET', '${s.sid}/state')).statusCode, 401);
    expect((await call('GET', '${s.sid}/state',
            headers: {'x-jam-token': 'x' * 32}))
        .statusCode, 401);

    var st = await json(await call('GET', '${s.sid}/state?since=-1',
        headers: auth));
    final v0 = st['version'] as int;
    expect(v0, greaterThan(0));

    final add = JamCommand.add(const JamItem(
        id: 0, ownerDeviceId: 'guest', title: 'Song', ext: 'mp3', ref: '7'));
    final res = await call('POST', '${s.sid}/cmd', body: add.toJson(), headers: auth);
    expect(res.statusCode, 200);
    st = await json(res);
    expect(st['version'], v0 + 1);
    expect(host.state!.items.single.ownerDeviceId, 'guest');

    // guest can jump (D-160) but cannot end
    final jr = await call('POST', '${s.sid}/cmd',
        body: const JamCommand.jump(1).toJson(), headers: auth);
    expect(jr.statusCode, 200);
    final er = await call('POST', '${s.sid}/cmd',
        body: const JamCommand.end().toJson(), headers: auth);
    expect(er.statusCode, 403);
    // garbage
    expect((await call('POST', '${s.sid}/cmd', body: {'cmd': 'x'}, headers: auth))
        .statusCode, 400);
    // a second guest can join the running session
    expect((await call('POST', 'request', body: reqBody(id: 'g2'))).statusCode,
        202);
    expect(host.accept(seen.last.id), isNotNull);
    expect(host.memberIds, ['guest', 'g2']);
  });

  test('a leaving guest keeps its upcoming online items, loses the rest (D-93)', () async {
    await startSession();
    expect((await call('POST', 'request', body: reqBody(id: 'g2'))).statusCode, 202);
    host.accept(seen.last.id);
    JamItem item(String t, {String? ref, String? vid}) => JamItem(
        id: 0, ownerDeviceId: 'guest', title: t, ext: 'm4a', ref: ref, videoId: vid);
    host.apply(const JamCommand.add(JamItem(id: 0, ownerDeviceId: 'host', title: 'H', ext: 'mp3')),
        from: 'host');
    host.apply(JamCommand.add(item('lib', ref: '7')), from: 'guest');
    host.apply(JamCommand.add(item('yt', ref: 'yt:youtube:abc', vid: 'abc')), from: 'guest');
    host.apply(JamCommand.add(item('sc', ref: 'yt:soundcloud:9', vid: '9')), from: 'guest');

    host.removeMember('guest');

    // SoundCloud cannot be fetched again by the host: it goes.
    expect(host.state!.items.map((i) => i.title), ['H', 'yt']);
    expect(host.state!.items.last.ownerDeviceId, 'guest');
  });

  test('a leaving guest keeps its online item when it is the current one', () async {
    await startSession();
    expect((await call('POST', 'request', body: reqBody(id: 'g2'))).statusCode, 202);
    host.accept(seen.last.id);
    host.apply(
        const JamCommand.add(JamItem(
            id: 0, ownerDeviceId: 'guest', title: 'cur', ext: 'm4a', ref: 'yt:youtube:abc', videoId: 'abc')),
        from: 'guest');
    expect(host.state!.currentIndex, 0);

    host.removeMember('guest');

    expect(host.state!.items.map((i) => i.title), ['cur']);
  });

  test('the only guest leaves with an online track: the Jam stays on the host (D-221)', () async {
    await startSession();
    host.apply(
      const JamCommand.add(
        JamItem(id: 0, ownerDeviceId: 'host', title: 'H', ext: 'mp3'),
      ),
      from: 'host',
    );
    host.apply(
      const JamCommand.add(
        JamItem(
          id: 0,
          ownerDeviceId: 'guest',
          title: 'yt',
          ext: 'm4a',
          ref: 'yt:youtube:abc',
          videoId: 'abc',
        ),
      ),
      from: 'guest',
    );

    host.removeMember('guest');

    expect(host.memberIds, isEmpty);
    expect(host.state!.ended, false);
    expect(host.state!.items.map((i) => i.title), ['H', 'yt']);
  });

  test('long poll wakes up on change and times out otherwise', () async {
    final s = await startSession();
    final auth = {'x-jam-token': s.token};
    final v0 = host.state!.version;
    final timeout = await call('GET', '${s.sid}/state?since=$v0', headers: auth);
    expect((await json(timeout))['version'], v0);

    final pending = call('GET', '${s.sid}/state?since=$v0', headers: auth);
    host.apply(const JamCommand.volume(0.5));
    expect((await json(await pending))['version'], v0 + 1);
  });

  test('end is visible to the guest and then clears', () async {
    final s = await startSession();
    host.endSession();
    final st = await json(await call('GET', '${s.sid}/state?since=0',
        headers: {'x-jam-token': s.token}));
    expect(st['ended'], true);
    host.clearSession();
    expect((await call('GET', '${s.sid}/state',
            headers: {'x-jam-token': s.token}))
        .statusCode, 401);
  });

  test('serves only queued items it owns, with Range', () async {
    final dir = Directory.systemTemp.createTempSync('jam');
    addTearDown(() => dir.deleteSync(recursive: true));
    final f = File(p.join(dir.path, 'a.mp3'))..writeAsBytesSync(List.generate(100, (i) => i));
    host.resolveFile = (item) async => item.ref == 'mine' ? f.path : null;
    final s = await startSession();
    final auth = {'x-jam-file': host.fileToken!};
    host.apply(const JamCommand.add(
        JamItem(id: 0, ownerDeviceId: 'host', title: 'A', ext: 'mp3', ref: 'mine')));
    host.apply(const JamCommand.add(
        JamItem(id: 0, ownerDeviceId: 'host', title: 'B', ext: 'mp3', ref: 'secret')));

    final full = await call('GET', '${s.sid}/file/1', headers: auth);
    expect(full.statusCode, 200);
    expect((await full.read().expand((b) => b).toList()).length, 100);
    final part = await call('GET', '${s.sid}/file/1',
        headers: {...auth, 'range': 'bytes=10-19'});
    expect(part.statusCode, 206);
    // not in queue, unresolvable, no token
    expect((await call('GET', '${s.sid}/file/99', headers: auth)).statusCode, 404);
    expect((await call('GET', '${s.sid}/file/2', headers: auth)).statusCode, 404);
    expect((await call('GET', '${s.sid}/file/1')).statusCode, 401);
    // item owned by the guest is not served by the host
    host.apply(
        const JamCommand.add(
            JamItem(id: 0, ownerDeviceId: 'guest', title: 'C', ext: 'mp3', ref: 'mine')),
        from: 'guest');
    expect((await call('GET', '${s.sid}/file/3', headers: auth)).statusCode, 404);
  });

  test('serves the TrackMeta of queued owned items, library and cached', () async {
    host.resolveMeta = (item) async => switch (item.ref) {
          'lib' => const TrackMeta(title: 'Lib', isrc: 'USRC17607839'),
          'yt:abcdefghijk' => const TrackMeta(title: 'Cached', youtubeId: 'abcdefghijk'),
          _ => null,
        };
    final s = await startSession();
    final auth = {'x-jam-file': host.fileToken!};
    for (final ref in ['lib', 'yt:abcdefghijk', 'none']) {
      host.apply(JamCommand.add(
          JamItem(id: 0, ownerDeviceId: 'host', title: ref, ext: 'mp3', ref: ref)));
    }
    expect((await json(await call('GET', '${s.sid}/meta/1', headers: auth)))['isrc'],
        'USRC17607839');
    expect((await json(await call('GET', '${s.sid}/meta/2', headers: auth)))['youtubeId'],
        'abcdefghijk');
    // callback says unknown, not in queue, wrong sid, no token
    expect((await call('GET', '${s.sid}/meta/3', headers: auth)).statusCode, 404);
    expect((await call('GET', '${s.sid}/meta/99', headers: auth)).statusCode, 404);
    expect((await call('GET', 'wrong/meta/1', headers: auth)).statusCode, 401);
    expect((await call('GET', '${s.sid}/meta/1')).statusCode, 401);
  });

  test('serves the cover of queued owned items', () async {
    final img = File(p.join(Directory.systemTemp.createTempSync('jc').path, 'c.jpg'))
      ..writeAsBytesSync([1, 2, 3]);
    host.resolveCover = (item) async => item.ref == 'lib' ? img.path : null;
    final s = await startSession();
    final auth = {'x-jam-file': host.fileToken!};
    for (final ref in ['lib', 'none']) {
      host.apply(JamCommand.add(
          JamItem(id: 0, ownerDeviceId: 'host', title: ref, ext: 'mp3', ref: ref)));
    }
    final ok = await call('GET', '${s.sid}/cover/1', headers: auth);
    expect(ok.statusCode, 200);
    expect(await ok.read().expand((c) => c).toList(), [1, 2, 3]);
    expect((await call('GET', '${s.sid}/cover/2', headers: auth)).statusCode, 404);
    expect((await call('GET', 'wrong/cover/1', headers: auth)).statusCode, 401);
  });
}
