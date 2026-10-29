import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_part_feeder.dart';
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

  test('a lost answer: sent again only after states past the send do not have it', () async {
    final sent = <String>[];
    final f = lossy(sent);
    await f.update(st(1));
    await f.update(st(1)); // an old state again: nothing
    await f.update(st(2));
    expect(sent, ['1']);
    await f.update(st(3));
    expect(sent, ['1', '1']);
  });
}
