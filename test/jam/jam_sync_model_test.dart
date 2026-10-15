import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_state.dart';
import 'package:flutter_test/flutter_test.dart';

const host = 'host', a = 'a', b = 'b';

JamState base() => const JamState(
      hostDeviceId: host,
      outputDeviceId: host,
      participants: [
        JamParticipant(id: host, name: 'H'),
        JamParticipant(id: a, name: 'A', host: '10.0.0.2', port: 1),
        JamParticipant(id: b, name: 'B', host: '10.0.0.3', port: 1),
      ],
    );

JamState ok(JamState s, JamCommand c, String from, {int now = 10000}) {
  final r = applyCommand(s, c, from: from, nowMs: now);
  expect(r.isOk, true, reason: '${r.error}');
  return r.state!;
}

JamItem item() =>
    const JamItem(id: 0, ownerDeviceId: host, title: 't', ext: 'mp3', durationMs: 200000);

void main() {
  test('single output is exactly the phase 9 behaviour', () {
    var s = ok(base(), JamCommand.add(item()), host);
    s = ok(s, const JamCommand.play(), host);
    expect(s.synced, false);
    expect(s.outputs, [host]);
    expect(s.positionAt, 10000);
    expect(s.positionAtTime(12500), 2500);
  });

  test('several outputs start together a moment ahead', () {
    var s = ok(base(), JamCommand.add(item()), host);
    s = ok(s, const JamCommand.setOutputs([host, a]), b);
    expect(s.synced, true);
    expect(s.outputDeviceId, host);
    s = ok(s, const JamCommand.play(), a);
    expect(s.positionAt, 10000 + jamStartLeadMs);
    // before the scheduled instant the position holds
    expect(s.positionAtTime(10500), 0);
    expect(s.positionAtTime(10000 + jamStartLeadMs + 3000), 3000);
  });

  test('changing the set while playing re-aligns everyone', () {
    var s = ok(base(), JamCommand.add(item()), host);
    s = ok(s, const JamCommand.play(), host, now: 0);
    s = ok(s, const JamCommand.setOutputs([a, b]), host, now: 5000);
    expect(s.positionMs, 5000);
    expect(s.positionAt, 5000 + jamStartLeadMs);
    expect(s.outputs, [a, b]);
    // back to one device: plain again
    s = ok(s, const JamCommand.setOutputs([b]), host, now: 9000);
    expect(s.synced, false);
    expect(s.outputDeviceId, b);
    expect(s.outputDeviceIds, isEmpty);
  });

  test('seek, jump and next also get the lead when synced', () {
    var s = ok(base(), JamCommand.add(item()), host);
    s = ok(s, JamCommand.add(item()), host);
    s = ok(s, const JamCommand.setOutputs([host, a]), host);
    s = ok(s, const JamCommand.seek(40000), a);
    expect(s.positionAt, 10000 + jamStartLeadMs);
    s = ok(s, const JamCommand.jump(2), host, now: 20000);
    expect(s.positionAt, 20000 + jamStartLeadMs);
    expect(s.positionMs, 0);
  });

  test('invalid output sets are refused', () {
    final s = base();
    for (final ids in [
      <String>[],
      ['nobody'],
      [host, 'nobody']
    ]) {
      final r = applyCommand(s, JamCommand.setOutputs(ids), from: a, nowMs: 0);
      expect(r.error, JamError.invalid, reason: '$ids');
    }
    // duplicates collapse
    expect(ok(s, const JamCommand.setOutputs([a, a, b]), a).outputs, [a, b]);
  });

  test('json: outputs survive, old payloads still parse', () {
    var s = ok(base(), const JamCommand.setOutputs([a, b]), host);
    final back = JamState.tryParse(s.toJson())!;
    expect(back.outputs, [a, b]);
    final old = s.toJson()..remove('outputs');
    expect(JamState.tryParse(old)!.outputs, [a]);
    final c = JamCommand.tryParse(const JamCommand.setOutputs([a, b]).toJson())!;
    expect(c.deviceIds, [a, b]);
    expect(JamCommand.tryParse({'cmd': 'setOutputs', 'devices': []}), isNull);
    expect(JamCommand.tryParse({'cmd': 'setOutputs', 'devices': [1]}), isNull);
  });
}
