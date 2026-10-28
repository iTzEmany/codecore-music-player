import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_state.dart';
import 'package:flutter_test/flutter_test.dart';

const host = 'host', guest = 'guest';

JamItem item(String owner,
        {String title = 't', int dur = 100000, bool inherited = false}) =>
    JamItem(
        id: 0,
        ownerDeviceId: owner,
        title: title,
        ext: 'mp3',
        durationMs: dur,
        inherited: inherited);

/// Host queue: current track 'cur' followed by [n] inherited tracks.
JamState seeded(int n) {
  var s = ok(start(), JamCommand.add(item(host, title: 'cur')), host);
  for (var i = 0; i < n; i++) {
    s = ok(s, JamCommand.add(item(host, title: 'i$i', inherited: true)), host);
  }
  return s;
}

JamState start() => const JamState(hostDeviceId: host, outputDeviceId: host);

JamState ok(JamState s, JamCommand c, String from, {int now = 1000}) {
  final r = applyCommand(s, c, from: from, nowMs: now);
  expect(r.isOk, true, reason: '${r.error}');
  return r.state!;
}

JamError? err(JamState s, JamCommand c, String from) =>
    applyCommand(s, c, from: from, nowMs: 1000).error;

void main() {
  videoIdTests();
  unsafeIdsTests();
  test('add assigns ids, selects first, bumps version', () {
    var s = ok(start(), JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(guest)), guest);
    expect(s.items.map((i) => i.id), [1, 2]);
    expect(s.currentIndex, 0);
    expect(s.version, 2);
  });

  test('host next and jump move the index, start playing and bump version', () {
    var s = ok(start(), JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(host)), host);
    final v = s.version;
    s = ok(s, const JamCommand.jump(2), host);
    expect(s.currentIndex, 1);
    expect(s.playing, true);
    expect(s.version, v + 1);
    s = ok(s, const JamCommand.next(), host);
    expect(s.currentIndex, 2);
    expect(s.playing, true);
    expect(s.version, v + 2);
  });

  // Phase 63 lets the guest next/jump: rewrite only this case.
  test('guest next and jump are forbidden today', () {
    var s = ok(start(), JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(host)), host);
    expect(err(s, const JamCommand.next(), guest), JamError.forbidden);
    expect(err(s, const JamCommand.jump(2), guest), JamError.forbidden);
  });

  test('next and jump messages keep their exact JSON', () {
    expect(const JamCommand.next().toJson(), {'cmd': 'next'});
    expect(const JamCommand.jump(7).toJson(), {'cmd': 'jump', 'itemId': 7});
    expect(JamCommand.tryParse({'cmd': 'jump', 'itemId': 7})!.itemId, 7);
    expect(JamCommand.tryParse({'cmd': 'next'})!.type, JamCommandType.next);
  });

  test('remove keeps current index coherent', () {
    var s = start();
    for (var i = 0; i < 3; i++) {
      s = ok(s, JamCommand.add(item(host)), host);
    }
    s = ok(s, const JamCommand.jump(3), host);
    s = ok(s, const JamCommand.remove(1), host);
    expect(s.currentIndex, 1);
    expect(s.current!.id, 3);
    s = ok(s, const JamCommand.remove(3), host);
    expect(s.currentIndex, 0);
    expect(s.current!.id, 2);
  });

  test('guest removes only own, not the current one', () {
    var s = ok(start(), JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(guest)), guest);
    s = ok(s, JamCommand.add(item(guest)), guest);
    expect(err(s, const JamCommand.remove(1), guest), JamError.forbidden);
    s = ok(s, const JamCommand.remove(2), guest);
    expect(s.items.length, 2);
    s = ok(s, const JamCommand.jump(3), host);
    expect(err(s, const JamCommand.remove(3), guest), JamError.forbidden);
  });

  test('move preserves the playing item', () {
    var s = start();
    for (var i = 0; i < 3; i++) {
      s = ok(s, JamCommand.add(item(host)), host);
    }
    s = ok(s, const JamCommand.move(3, 0), guest);
    expect(s.items.map((i) => i.id), [3, 1, 2]);
    expect(s.current!.id, 1);
    expect(err(s, const JamCommand.move(1, 9), guest), JamError.invalid);
  });

  test('position math across play/pause', () {
    var s = ok(start(), JamCommand.add(item(host)), host, now: 0);
    s = ok(s, const JamCommand.play(), host, now: 0);
    expect(s.positionAtTime(5000), 5000);
    s = ok(s, const JamCommand.pause(), guest, now: 5000);
    expect(s.positionAtTime(9000), 5000);
    expect(err(s, const JamCommand.seek(999999), guest), JamError.invalid);
    s = ok(s, const JamCommand.seek(20000), guest, now: 9000);
    expect(s.positionMs, 20000);
  });

  test('setOutput only host or requester; version monotonic', () {
    var s = ok(start(), JamCommand.add(item(host)), host);
    final v = s.version;
    s = ok(s, const JamCommand.setOutput(guest), guest);
    expect(s.outputDeviceId, guest);
    expect(s.version, greaterThan(v));
    expect(err(s, const JamCommand.setOutput('stranger'), guest),
        JamError.invalid);
  });

  test('trackEnded advances once; stale id ignored', () {
    var s = start();
    s = ok(s, JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(host)), host);
    s = ok(s, const JamCommand.trackEnded(1), guest);
    expect(s.currentIndex, 1);
    final again = ok(s, const JamCommand.trackEnded(1), guest);
    expect(again.currentIndex, 1);
    s = ok(s, const JamCommand.trackEnded(2), guest);
    expect(s.playing, false);
  });

  test('limit and end', () {
    var s = start();
    for (var i = 0; i < maxJamItems; i++) {
      s = ok(s, JamCommand.add(item(host)), host);
    }
    expect(err(s, JamCommand.add(item(host)), host), JamError.full);
    expect(err(s, const JamCommand.end(), guest), JamError.forbidden);
    s = ok(s, const JamCommand.end(), host);
    expect(err(s, const JamCommand.play(), host), JamError.ended);
  });

  test('json round trip and strict parsing', () {
    var s = ok(start(), JamCommand.add(item(host, title: 'A')), host);
    s = ok(s, const JamCommand.play(), host);
    final back = JamState.tryParse(s.toJson())!;
    expect(back.items.single.title, 'A');
    expect(back.version, s.version);
    expect(JamState.tryParse({'version': 'x'}), isNull);
    expect(JamCommand.tryParse({'cmd': 'nope'}), isNull);
    expect(
        JamItem.tryParse({'id': 1, 'owner': 'a', 'title': 'x', 'ext': 'exe'}),
        isNull);
    final c = JamCommand.tryParse(JamCommand.add(item(guest)).toJson())!;
    expect(c.type, JamCommandType.add);
  });

  test('guest add lands right after current, before inherited items', () {
    final s = ok(seeded(2), JamCommand.add(item(guest, title: 'g')), guest);
    expect(s.items.map((i) => i.title), ['cur', 'g', 'i0', 'i1']);
    expect(s.currentIndex, 0);
  });

  test('second add lands after the first add', () {
    var s = ok(seeded(2), JamCommand.add(item(guest, title: 'g1')), guest);
    s = ok(s, JamCommand.add(item(host, title: 'h2')), host);
    expect(s.items.map((i) => i.title), ['cur', 'g1', 'h2', 'i0', 'i1']);
  });

  test('move: inherited track dragged into the added block becomes added', () {
    var s = ok(seeded(2), JamCommand.add(item(guest, title: 'a1')), guest);
    s = ok(s, JamCommand.add(item(guest, title: 'a2')), guest);
    s = ok(s, JamCommand.move(s.items[3].id, 1), host);
    expect(s.items[1].title, 'i0');
    expect(s.items[1].inherited, false);
    s = ok(s, JamCommand.add(item(guest, title: 'b')), guest);
    expect(s.items.map((i) => i.title), ['cur', 'i0', 'a1', 'a2', 'b', 'i1']);
  });

  test('move: added track dragged to the end becomes inherited', () {
    var s = ok(seeded(1), JamCommand.add(item(guest, title: 'a')), guest);
    s = ok(s, JamCommand.move(s.items[1].id, 2), host);
    expect(s.items.last.title, 'a');
    expect(s.items.last.inherited, true);
  });

  test('add after next lands right after the new current', () {
    var s = ok(seeded(2), const JamCommand.next(), host);
    s = ok(s, JamCommand.add(item(guest, title: 'g')), guest);
    expect(s.items.map((i) => i.title), ['cur', 'i0', 'g', 'i1']);
  });

  test('add when current is the last item goes to the end', () {
    var s = ok(seeded(1), const JamCommand.next(), host);
    s = ok(s, JamCommand.add(item(guest, title: 'g')), guest);
    expect(s.items.map((i) => i.title), ['cur', 'i0', 'g']);
  });

  test('full queue: add evicts the last inherited item', () {
    final s0 = seeded(maxJamItems - 1);
    expect(s0.items.length, maxJamItems);
    final s = ok(s0, JamCommand.add(item(guest, title: 'g')), guest);
    expect(s.items.length, maxJamItems);
    expect(s.items[1].title, 'g');
    expect(s.items.last.title, 'i${maxJamItems - 3}');
  });

  test('full queue without inherited items after current fails', () {
    var s = start();
    for (var i = 0; i < maxJamItems; i++) {
      s = ok(s, JamCommand.add(item(host)), host);
    }
    expect(err(s, JamCommand.add(item(guest)), guest), JamError.full);
  });

  test('guest cannot send an inherited add', () {
    final s = ok(seeded(1), JamCommand.add(item(guest, title: 'g', inherited: true)), guest);
    expect(s.items.map((i) => i.title), ['cur', 'g', 'i0']);
    expect(s.items[1].inherited, false);
  });

  test('JamItem json keeps inherited', () {
    expect(JamItem.tryParse(item(host, inherited: true).toJson())!.inherited, true);
    expect(JamItem.tryParse(item(host).toJson())!.inherited, false);
  });
}

void videoIdTests() {
  test('videoId round-trips JSON; JSON without it reads null', () {
    final i = JamItem(
        id: 1, ownerDeviceId: 'a', title: 't', ext: 'm4a', ref: 'yt:youtube:abc', videoId: 'abc');
    final back = JamItem.tryParse(i.toJson()..['extra'] = 1)!;
    expect(back.videoId, 'abc');
    expect(back.ref, 'yt:youtube:abc');
    expect(i.copyWith(id: 2).videoId, 'abc');
    expect((i.toJson()..remove('vid')).let(JamItem.tryParse)!.videoId, isNull);
  });
}

void unsafeIdsTests() {
  JamItem? parse(String ref, String vid) => JamItem.tryParse({
        'id': 1, 'owner': 'o', 'title': 't', 'ext': 'm4a', 'ref': ref, 'vid': vid});

  test('a guest ref or vid that is not a plain id is dropped', () {
    final good = parse('yt:soundcloud:123-a_B', 'abc_-1')!;
    expect([good.ref, good.videoId], ['yt:soundcloud:123-a_B', 'abc_-1']);
    expect(parse('7', 'x')!.ref, '7');
    for (final bad in ['yt:youtube:../../../evil', 'yt:other:abc', 'yt:youtube:', 'x/7']) {
      expect(parse(bad, 'a')!.ref, isNull, reason: bad);
    }
    expect(parse('7', 'a&list=PLx')!.videoId, isNull);
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
