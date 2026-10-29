import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_turns.dart';
import 'package:flutter_test/flutter_test.dart';

JamItem it(String owner, String t, {bool inh = false}) =>
    JamItem(id: 0, ownerDeviceId: owner, title: t, ext: 'mp3', inherited: inh);

String run(List<JamItem> l, int cur, List<String> order) =>
    togetherOrder(l, cur, order).map((i) => i.title).join(' ');

void main() {
  const order = ['h', 'a', 'b'];
  final cases = <(String, List<JamItem>, int, String)>[
    (
      'two people, uneven',
      [it('h', 'h0'), it('h', 'h1'), it('h', 'h2'), it('a', 'a1')],
      0,
      'h0 a1 h1 h2',
    ),
    (
      'starts after the owner of the current',
      [it('a', 'a0'), it('a', 'a1'), it('h', 'h1'), it('b', 'b1')],
      0,
      'a0 b1 h1 a1',
    ),
    (
      'three, uneven, skip who is out',
      [
        it('h', 'h0'),
        it('b', 'b1'),
        it('b', 'b2'),
        it('b', 'b3'),
        it('a', 'a1'),
      ],
      0,
      'h0 a1 b1 b2 b3',
    ),
    (
      'owner not in the list keeps its index',
      [it('h', 'h0'), it('x', 'x1'), it('a', 'a1'), it('h', 'h1')],
      0,
      'h0 x1 a1 h1',
    ),
    (
      'G1 left: its online tracks stay in place (D-210)',
      [
        it('h', 'H0'),
        it('g1', 'G1a'),
        it('g2', 'G2a'),
        it('h', 'H1'),
        it('g1', 'G1b'),
        it('g2', 'G2b'),
        it('h', 'H2'),
      ],
      0,
      'H0 G1a G2a H1 G1b G2b H2',
    ),
    (
      'no current: first participant first',
      [it('b', 'b1'), it('h', 'h1')],
      -1,
      'h1 b1',
    ),
    ('current is last: untouched', [it('a', 'a1'), it('h', 'h1')], 1, 'a1 h1'),
    (
      'inherited items count as their owner part',
      [it('h', 'h0'), it('h', 'i0', inh: true), it('a', 'a1'), it('a', 'a2')],
      0,
      'h0 a1 i0 a2',
    ),
  ];
  for (final (name, l, cur, want) in cases) {
    test(name, () => expect(run(l, cur, name.startsWith('G1 left') ? ['h', 'g2'] : order), want));
  }

  test('a current index below -1 is treated as nothing playing', () {
    expect(run([it('h', 'h0'), it('a', 'a1'), it('h', 'h1')], -2, order), 'h0 a1 h1');
  });
}
