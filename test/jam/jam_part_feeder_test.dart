import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_part_feeder.dart';
import 'package:codecore/services/jam/jam_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('part keys: the id, and id~n for repeats; the id comes back from the key', () {
    expect(jamPartKeys([5, 7, 5, 5]), ['5', '7', '5~1', '5~2']);
    expect(jamPartKeyId('5~2'), 5);
  });

  test('a send that fails or throws never loses the track', () async {
    var calls = 0;
    final sent = <String>[];
    final f = JamPartFeeder(
      ownId: 'a',
      part: ['1', '2'],
      send: (c) async {
        if (++calls == 1) throw StateError('network');
        if (calls == 2) return const JamResult.fail(JamError.full);
        sent.add(c.item!.partKey!);
        return JamResult.ok(const JamState(version: 9, hostDeviceId: 'h', outputDeviceId: 'h'));
      },
      itemOf: (k) async => JamItem(id: 0, ownerDeviceId: 'a', title: k, ext: 'mp3', partKey: k),
      suggest: (_) async => null,
    );
    const s = JamState(version: 1, hostDeviceId: 'h', outputDeviceId: 'h', mode: JamMode.together);
    await f.update(s); // throws: sent or not, nobody knows
    expect(f.unsent, ['1', '2']);
    await f.update(s); // full: back in the part
    expect(f.unsent, ['1', '2']);
    await f.update(s);
    expect(sent, ['2']); // '1' may already be in the Jam: not sent again
    expect(f.unsent, ['1', '2']); // sent, waiting to be seen in the Jam
  });

  JamState st(int v, [List<JamItem> items = const []]) => JamState(
      version: v,
      hostDeviceId: 'h',
      outputDeviceId: 'h',
      mode: JamMode.together,
      items: items,
      currentIndex: items.isEmpty ? -1 : 0);

  JamPartFeeder lossy(List<String> sent) => JamPartFeeder(
        ownId: 'a',
        part: ['1'],
        send: (c) async {
          sent.add(c.item!.partKey!);
          return const JamResult.fail(JamError.notFound); // transport error
        },
        itemOf: (k) async => JamItem(id: 0, ownerDeviceId: 'a', title: k, ext: 'mp3', partKey: k),
        suggest: (_) async => null,
      );

  test('a lost answer: the add the host did apply is not sent twice', () async {
    final sent = <String>[];
    final f = lossy(sent);
    await f.update(st(1));
    final applied = JamItem(id: 1, ownerDeviceId: 'a', title: '1', ext: 'mp3', partKey: '1');
    await f.update(st(2, [applied])); // a late state shows it
    await f.update(st(3, [applied]));
    await f.update(st(4, [applied]));
    expect(sent, ['1']);
  });

  test('a lost answer: sent again at the first state past the send without it', () async {
    final sent = <String>[];
    final f = lossy(sent);
    await f.update(st(1));
    await f.update(st(1)); // an old state again: nothing
    expect(sent, ['1']);
    await f.update(st(2));
    expect(sent, ['1', '1']);
  });

  JamItem fedItem(String k) =>
      JamItem(id: 0, ownerDeviceId: 'a', title: k, ext: 'mp3', partKey: k);

  test('a lost answer, a host that is several versions ahead: one copy in the Jam', () async {
    var host = const JamState(
        version: 1, hostDeviceId: 'a', outputDeviceId: 'a', mode: JamMode.together);
    var lose = true;
    final f = JamPartFeeder(
      ownId: 'a',
      part: ['1'],
      send: (c) async {
        final r = applyCommand(host, c, from: 'a', nowMs: 0);
        host = r.state!;
        if (lose) {
          lose = false;
          return const JamResult.fail(JamError.notFound); // applied, answer lost
        }
        return r;
      },
      itemOf: (k) async => fedItem(k),
      suggest: (_) async => null,
    );
    await f.update(st(1));
    host = applyCommand(host, const JamCommand.setMode(JamMode.together), from: 'a', nowMs: 0).state!;
    await f.update(st(2));
    await f.update(st(3));
    await f.update(host);
    expect(host.items.where((i) => i.partKey == '1'), hasLength(1));
  });

  test('itemOf failing once: the key stays in the part and is tried again', () async {
    var n = 0;
    final sent = <String>[];
    final f = JamPartFeeder(
      ownId: 'a',
      part: ['1'],
      send: (c) async {
        sent.add(c.item!.partKey!);
        return JamResult.ok(st(5));
      },
      itemOf: (k) async => ++n == 1 ? throw StateError('db') : fedItem(k),
      suggest: (_) async => null,
    );
    await f.update(st(1));
    expect(f.unsent, ['1']);
    await f.update(st(1));
    expect(sent, ['1']);
  });

  test('the quota: with the limit already in the Jam nothing more is sent', () async {
    JamState withOwn(int n) => JamState(
          version: 1,
          hostDeviceId: 'h',
          outputDeviceId: 'h',
          mode: JamMode.together,
          participants: const [
            JamParticipant(id: 'h', name: 'h'),
            JamParticipant(id: 'a', name: 'a'),
          ],
          currentIndex: 0,
          items: [
            const JamItem(id: 0, ownerDeviceId: 'h', title: 'cur', ext: 'mp3'),
            for (var i = 0; i < n; i++)
              JamItem(id: i + 1, ownerDeviceId: 'a', title: 'x$i', ext: 'mp3', partKey: 'x$i'),
          ],
        );
    final sent = <String>[];
    JamPartFeeder make() => JamPartFeeder(
          ownId: 'a',
          part: ['k'],
          send: (c) async {
            sent.add(c.item!.partKey!);
            return JamResult.ok(st(9));
          },
          itemOf: (k) async => fedItem(k),
          suggest: (_) async => null,
        );
    await make().update(withOwn(100)); // ceil(200 / 2)
    expect(sent, isEmpty);
    await make().update(withOwn(99));
    expect(sent, ['k']);
  });

  test('a sent key missing from a state at its own version was removed: forgotten', () async {
    final sent = <String>[];
    final f = JamPartFeeder(
      ownId: 'a',
      part: ['1'],
      send: (c) async {
        sent.add('1');
        return JamResult.ok(st(5));
      },
      itemOf: (k) async => fedItem(k),
      suggest: (_) async => null,
    );
    await f.update(st(4));
    expect(f.unsent, ['1']);
    await f.update(st(5));
    expect(f.unsent, isEmpty);
    expect(sent, ['1']);
  });

  test('one suggestion in flight: no second one, even when our own track arrives', () async {
    var asked = 0;
    final f = JamPartFeeder(
      ownId: 'a',
      part: const [],
      send: (c) async => JamResult.ok(st(3)),
      itemOf: (k) async => null,
      suggest: (_) async {
        asked++;
        return const JamItem(id: 0, ownerDeviceId: 'a', title: 's', ext: 'mp3', suggested: true);
      },
    );
    final cur = const JamItem(id: 0, ownerDeviceId: 'h', title: 'cur', ext: 'mp3');
    await f.update(st(1, [cur]));
    await f.update(st(2, [cur])); // not observed yet
    expect(asked, 1);
    await f.update(st(3, [
      cur,
      const JamItem(id: 1, ownerDeviceId: 'a', title: 's', ext: 'mp3', suggested: true),
    ]));
    expect(asked, 1);
  });
}
