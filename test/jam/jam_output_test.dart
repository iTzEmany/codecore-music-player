import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/jam_output.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late JamOutput out;
  var now = 0;
  final ended = <int>[];
  final failed = <int>[];

  const a = JamItem(id: 1, ownerDeviceId: 'me', title: 'A', ext: 'mp3', ref: 'x');
  const b = JamItem(id: 2, ownerDeviceId: 'peer', title: 'B', ext: 'mp3');

  JamState st({
    List<JamItem> items = const [a, b],
    int cur = 0,
    bool playing = true,
    String output = 'me',
    int pos = 0,
    int at = 0,
  }) =>
      JamState(
        version: 1,
        items: items,
        currentIndex: cur,
        playing: playing,
        positionMs: pos,
        positionAt: at,
        hostDeviceId: 'host',
        outputDeviceId: output,
      );

  setUp(() {
    now = 0;
    ended.clear();
    failed.clear();
    backend = FakeBackend();
    out = JamOutput(
      deviceId: 'me',
      backend: backend,
      nowMs: () => now,
      resolve: (i) async => i.ownerDeviceId == 'me'
          ? JamSource.local('/music/${i.ref}.mp3')
          : JamSource.remote(
              Uri.parse('http://10.0.0.2:1/jam/s/file/${i.id}'), {'x-jam-token': 't'}),
    )
      ..onTrackEnded = ended.add
      ..onItemFailed = failed.add;
  });

  test('plays own item locally, remote item with the token header', () async {
    await out.apply(st());
    expect(backend.loaded, ['/music/x.mp3']);
    expect(backend.playing, true);
    await out.apply(st(cur: 1));
    expect(backend.loadedUris.single.headers['x-jam-token'], 't');
    expect(backend.loadedUris.single.uri.path, '/jam/s/file/2');
  });

  test('not the output: stays silent and stops when output moves away', () async {
    await out.apply(st(output: 'host'));
    expect(backend.loaded, isEmpty);
    await out.apply(st());
    expect(backend.playing, true);
    await out.apply(st(output: 'host'));
    expect(backend.playing, false);
    expect(out.loadedItemId, isNull);
  });

  test('pause follows state; same item is not reloaded', () async {
    await out.apply(st());
    await out.apply(st(playing: false));
    expect(backend.playing, false);
    await out.apply(st());
    expect(backend.loaded, hasLength(1));
  });

  test('drift tolerance: small drift ignored, big drift seeks', () async {
    final seeks = <Duration>[];
    final b2 = _SeekSpy(seeks);
    final o = JamOutput(
        deviceId: 'me', backend: b2, nowMs: () => now,
        resolve: (i) async => const JamSource.local('/a.mp3'));
    await o.apply(st());
    b2.posC.add(const Duration(seconds: 10));
    await Future<void>.delayed(Duration.zero);
    now = 10500; // target 10.5s vs 10s: inside tolerance
    await o.apply(st());
    expect(seeks, isEmpty);
    now = 14000; // 4s away
    await o.apply(st());
    expect(seeks, [const Duration(seconds: 14)]);
  });

  test('reports natural end once, and failures', () async {
    await out.apply(st());
    backend.stateC.add(BackendState.completed);
    backend.stateC.add(BackendState.completed);
    await Future<void>.delayed(Duration.zero);
    expect(ended, [1]);

    backend.failing.add('http://10.0.0.2:1/jam/s/file/2');
    await out.apply(st(cur: 1));
    expect(failed, [2]);
  });
}

class _SeekSpy extends FakeBackend {
  _SeekSpy(this.seeks);
  final List<Duration> seeks;
  @override
  Future<void> seek(Duration position) async => seeks.add(position);
}
