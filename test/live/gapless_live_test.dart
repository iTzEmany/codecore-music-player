// Opt-in, Linux with PipeWire: the real JustAudioBackend (just_audio → media_kit
// → libmpv) plays the click fixtures through its two-track window while
// pw-record captures the sound card's monitor; the click spacing shows any gap.
// Plays quietly for ~10 s.
//   CODECORE_LIVE=1 flutter test test/live/gapless_live_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:codecore/services/audio/audio_backend.dart';
import 'package:codecore/services/audio/just_audio_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;

/// Click onsets (ms) of a 16-bit mono WAV written by pw-record.
List<double> clickTimes(Uint8List wav) {
  final data = ByteData.sublistView(wav);
  final rate = data.getUint32(24, Endian.little);
  var start = 44;
  for (var i = 12; i + 8 < wav.length;) {
    final id = String.fromCharCodes(wav.sublist(i, i + 4));
    final size = data.getUint32(i + 4, Endian.little);
    if (id == 'data') {
      start = i + 8;
      break;
    }
    i += 8 + size;
  }
  final n = (wav.length - start) ~/ 2;
  var peak = 1;
  for (var i = 0; i < n; i++) {
    final v = data.getInt16(start + i * 2, Endian.little).abs();
    if (v > peak) peak = v;
  }
  final times = <double>[];
  var last = -1 << 30;
  for (var i = 0; i < n; i++) {
    final v = data.getInt16(start + i * 2, Endian.little).abs();
    if (v > peak * 0.3 && i - last > rate ~/ 10) {
      times.add(i / rate * 1000);
      last = i;
    }
  }
  return times;
}

void main() {
  final live = Platform.environment['CODECORE_LIVE'] == '1' && Platform.isLinux;

  /// The first output the sound server lists (CODECORE_SINK overrides it).
  String findSink() {
    final env = Platform.environment['CODECORE_SINK'];
    if (env != null) return env;
    final out = Process.runSync('pw-cli', ['ls', 'Node']).stdout as String;
    for (final block in out.split(RegExp(r'\n\s*id '))) {
      if (!block.contains('media.class = "Audio/Sink"')) continue;
      final name = RegExp(r'node\.name = "([^"]+)"').firstMatch(block);
      if (name != null) return name.group(1)!;
    }
    throw StateError('no Audio/Sink found by pw-cli');
  }

  /// [window] false loads each track after the previous one ended, as the
  /// handler does in normal mode.
  Future<List<double>> play(List<String> files, {bool window = true}) async {
    final sink = findSink();
    final dir = Directory.systemTemp.createTempSync('gapless_live');
    final wav = p.join(dir.path, 'rec.wav');
    final rec = await Process.start('pw-record', [
      '--target', sink, '-P', 'stream.capture.sink=true',
      '--rate', '48000', '--channels', '1', '--format', 's16', wav,
    ]);
    await Future<void>.delayed(const Duration(seconds: 1));
    final backend = JustAudioBackend();
    await backend.setVolume(0.15);
    final done = Completer<void>();
    var index = 0;
    final subs = [
      backend.advanced.listen((_) {
        index++;
        if (index + 1 < files.length) unawaited(backend.setNext(files[index + 1]));
      }),
      backend.state.listen((s) async {
        if (s != BackendState.completed) return;
        if (!window && index + 1 < files.length) {
          index++;
          await backend.load(files[index]);
          await backend.play();
        } else if (!done.isCompleted) {
          done.complete();
        }
      }),
    ];
    await backend.load(files[0]);
    if (window) await backend.setNext(files[1]);
    await backend.play();
    await done.future.timeout(const Duration(seconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    for (final s in subs) {
      await s.cancel();
    }
    await backend.dispose();
    rec.kill(ProcessSignal.sigterm);
    await rec.exitCode;
    final times = clickTimes(File(wav).readAsBytesSync());
    dir.deleteSync(recursive: true);
    return times;
  }

  String fix(String name) => p.absolute('test/fixtures/gapless/$name');

  void expectNoGap(List<double> t) {
    expect(t, hasLength(18), reason: '6 clicks per file');
    for (final seam in [5, 11]) {
      final gap = t[seam + 1] - t[seam] - 500;
      expect(gap.abs(), lessThan(20), reason: 'seam after click ${seam + 1}: ${gap.toStringAsFixed(1)} ms');
    }
    // ignore: avoid_print
    print('seams: ${[5, 11].map((s) => (t[s + 1] - t[s] - 500).toStringAsFixed(1))} ms');
  }

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (live) JustAudioMediaKit.ensureInitialized();
  });

  const timeout = Timeout(Duration(minutes: 2));
  final skip = live ? false : 'set CODECORE_LIVE=1 on Linux with PipeWire';

  test('three mp3 through the window: no audible gap', () async {
    expectNoGap(await play([for (var i = 1; i <= 3; i++) fix('click-$i.mp3')]));
  }, skip: skip, timeout: timeout);

  test('three flac through the window: no audible gap', () async {
    expectNoGap(await play([for (var i = 1; i <= 3; i++) fix('click-$i.flac')]));
  }, skip: skip, timeout: timeout);

  test('for comparison: the same three mp3 loaded one after the other (normal mode)', () async {
    final t = await play([for (var i = 1; i <= 3; i++) fix('click-$i.mp3')], window: false);
    expect(t, hasLength(18));
    // ignore: avoid_print
    print('normal mode seams: ${[5, 11].map((s) => (t[s + 1] - t[s] - 500).toStringAsFixed(1))} ms');
  }, skip: skip, timeout: timeout);

  test('mp3 then flac then mp3: no audible gap', () async {
    expectNoGap(await play([fix('click-1.mp3'), fix('click-2.flac'), fix('click-3.mp3')]));
  }, skip: skip, timeout: timeout);
}
