import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_transport.dart';
import 'package:flutter_test/flutter_test.dart';

JamItem item(int id, String title, {int ms = 180000}) => JamItem(
  id: id,
  ownerDeviceId: 'host',
  title: title,
  ext: 'mp3',
  artist: 'Artist',
  album: 'Album',
  durationMs: ms,
);

JamState state({
  bool playing = true,
  int pos = 10000,
  int at = 1000,
  int index = 0,
  List<JamItem>? items,
}) => JamState(
  version: 1,
  items: items ?? [item(1, 'One'), item(2, 'Two')],
  currentIndex: index,
  playing: playing,
  positionMs: pos,
  positionAt: at,
  hostDeviceId: 'host',
  outputDeviceId: 'host',
);

void main() {
  late List<JamCommand> sent;
  late int now;

  JamTransport make() {
    sent = [];
    now = 1000;
    return JamTransport(
      send: (c) async {
        sent.add(c);
        return null;
      },
      nowMs: () => now,
    );
  }

  test('nothing to show before the first state or with an empty queue', () {
    final t = make();
    expect(t.status.hasItem, isFalse);
    t.update(state(items: const [], index: -1));
    expect(t.status.hasItem, isFalse);
  });

  test('the current item, and a position that moves while it plays', () {
    final t = make()..update(state());
    expect(t.status.title, 'One');
    expect(t.status.artist, 'Artist');
    expect(t.status.album, 'Album');
    expect(t.status.duration, const Duration(minutes: 3));
    expect(t.status.playing, isTrue);
    expect(t.status.position, const Duration(seconds: 10));
    now = 1000 + 5000;
    expect(t.status.position, const Duration(seconds: 15));
  });

  test('a paused Jam keeps its position', () {
    final t = make()..update(state(playing: false, pos: 20000));
    now += 60000;
    expect(t.status.position, const Duration(seconds: 20));
    expect(t.status.playing, isFalse);
  });

  test('the position stays inside the track', () {
    final t = make()..update(state(pos: 170000));
    now += 60000;
    expect(t.status.position, const Duration(minutes: 3));
    final early = make()..update(state(pos: 0, at: 5000));
    now = 1000; // the host clock is ahead of ours: never negative
    expect(early.status.position, Duration.zero);
  });

  test('the buttons become Jam commands', () async {
    final t = make()..update(state());
    await t.play();
    await t.pause();
    await t.next();
    await t.seek(const Duration(seconds: 30));
    expect(sent.map((c) => c.type), [
      JamCommandType.play,
      JamCommandType.pause,
      JamCommandType.next,
      JamCommandType.seek,
    ]);
    expect(sent.last.positionMs, 30000);
  });

  test('everyone can skip, and previous follows the player rule', () async {
    final t = make()..update(state(index: 1, pos: 0, at: 1000));
    expect(t.status.canSkip, isTrue);
    await t.previous(); // 0 s in: back to the item before
    now = 1000 + 5000;
    await t.previous(); // 5 s in: restart
    expect(sent.map((c) => c.type), [JamCommandType.jump, JamCommandType.seek]);
    expect(sent.first.itemId, 1);
    expect(sent.last.positionMs, 0);
  });

  test('every state change is announced', () async {
    final t = make();
    final seen = <String?>[];
    t.changes.listen((s) => seen.add(s.title));
    t.update(state());
    t.update(state(index: 1));
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['One', 'Two']);
    await t.dispose();
  });
}
