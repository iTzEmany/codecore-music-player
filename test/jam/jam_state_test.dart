import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_state.dart';
import 'package:flutter_test/flutter_test.dart';

const host = 'host', guest = 'guest';

JamItem item(String owner, {String title = 't', int dur = 100000}) => JamItem(
    id: 0, ownerDeviceId: owner, title: title, ext: 'mp3', durationMs: dur);

JamState start() => const JamState(hostDeviceId: host, outputDeviceId: host);

JamState ok(JamState s, JamCommand c, String from, {int now = 1000}) {
  final r = applyCommand(s, c, from: from, nowMs: now);
  expect(r.isOk, true, reason: '${r.error}');
  return r.state!;
}

JamError? err(JamState s, JamCommand c, String from) =>
    applyCommand(s, c, from: from, nowMs: 1000).error;

void main() {
  test('add assigns ids, selects first, bumps version', () {
    var s = ok(start(), JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(guest)), guest);
    expect(s.items.map((i) => i.id), [1, 2]);
    expect(s.currentIndex, 0);
    expect(s.version, 2);
  });

  test('add on behalf of someone else is forbidden', () {
    expect(err(start(), JamCommand.add(item(host)), guest), JamError.forbidden);
  });

  test('guest cannot next or jump; host can', () {
    var s = ok(start(), JamCommand.add(item(host)), host);
    s = ok(s, JamCommand.add(item(host)), host);
    expect(err(s, const JamCommand.next(), guest), JamError.forbidden);
    expect(err(s, const JamCommand.jump(2), guest), JamError.forbidden);
    s = ok(s, const JamCommand.jump(2), host);
    expect(s.currentIndex, 1);
    expect(s.playing, true);
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
}
