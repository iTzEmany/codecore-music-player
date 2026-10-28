import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/services/jam/jam_clock.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real controller, with only the state and the wire replaced.
class _Jam extends JamController {
  _Jam(this.initial);
  final JamUiState initial;
  final sent = <JamCommand>[];
  JamError? oldHost; // answer to `previous` (null: the host knows it)

  @override
  JamUiState build() => initial;

  @override
  Future<JamError?> send(JamCommand cmd) async {
    sent.add(cmd);
    return cmd.type == JamCommandType.previous ? oldHost : null;
  }
}

JamUiState _state({required int index, required int positionMs}) => JamUiState(
      phase: JamPhase.active,
      role: JamRole.guest,
      jam: JamState(
        version: 1,
        items: const [
          JamItem(id: 10, ownerDeviceId: 'h', title: 'A', ext: 'mp3', durationMs: 100000),
          JamItem(id: 20, ownerDeviceId: 'h', title: 'B', ext: 'mp3', durationMs: 100000),
        ],
        currentIndex: index,
        playing: true,
        positionMs: positionMs,
        positionAt: 5000,
        hostDeviceId: 'h',
        outputDeviceId: 'h',
      ),
    );

(ProviderContainer, _Jam) _make(JamUiState s) {
  final jam = _Jam(s);
  final c = ProviderContainer(overrides: [jamProvider.overrideWith(() => jam)]);
  addTearDown(c.dispose);
  c.read(jamProvider);
  return (c, jam);
}

void main() {
  test('previous() jumps to the item before when the position is under 3 s', () async {
    final (c, jam) = _make(_state(index: 1, positionMs: 1000));
    jam.debugSetClock(JamClock(probe: () async => null, localNowMs: () => 5000));
    await c.read(jamProvider.notifier).previous();
    expect(jam.sent.single.type, JamCommandType.previous);

    jam.oldHost = JamError.invalid;
    jam.sent.clear();
    await c.read(jamProvider.notifier).previous();
    expect(jam.sent.map((c) => c.type), [JamCommandType.previous, JamCommandType.jump]);
    expect(jam.sent.last.itemId, 10);
  });

  test('previous() does not fall back on an error other than invalid', () async {
    final (c, jam) = _make(_state(index: 1, positionMs: 1000));
    jam.oldHost = JamError.forbidden;
    jam.debugSetClock(JamClock(probe: () async => null, localNowMs: () => 5000));
    expect(await c.read(jamProvider.notifier).previous(), JamError.forbidden);
    expect(jam.sent.map((c) => c.type), [JamCommandType.previous]);
  });

  test('fallback to an old host restarts after 3 s and on the first one', () async {
    final (c, jam) = _make(_state(index: 1, positionMs: 1000));
    jam.oldHost = JamError.invalid;
    jam.debugSetClock(JamClock(probe: () async => null, localNowMs: () => 9000));
    await c.read(jamProvider.notifier).previous();
    expect(jam.sent.last.type, JamCommandType.seek);

    final (c2, jam2) = _make(_state(index: 0, positionMs: 1000));
    jam2.oldHost = JamError.invalid;
    jam2.debugSetClock(JamClock(probe: () async => null, localNowMs: () => 5000));
    await c2.read(jamProvider.notifier).previous();
    expect(jam2.sent.last.type, JamCommandType.seek);
  });

  test('jamNowMs() is the host clock: the local one plus the synced offset', () async {
    final (c, jam) = _make(_state(index: 0, positionMs: 0));
    final clock = JamClock(
      // The host is 40 s ahead of this device.
      probe: () async => (t0: 1000, hostMs: 41000, t1: 1000),
      localNowMs: () => 2000,
    );
    await clock.sync();
    jam.debugSetClock(clock);
    expect(c.read(jamProvider.notifier).jamNowMs(), 42000);
  });
}
