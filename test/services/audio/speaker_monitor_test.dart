import 'dart:async';

import 'package:codecore/services/audio/bluetooth_outputs.dart';
import 'package:codecore/services/audio/speaker_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

BluetoothOutput _out(String addr, [int? cls, String name = 'Dev']) =>
    BluetoothOutput(name: name, address: addr, deviceClass: cls);

class _Rig {
  var snap = const BluetoothSnapshot(permission: true);
  final changed = StreamController<void>.broadcast();
  final seen = StreamController<void>.broadcast();
  var requests = 0;
  var requestResult = true;
  var active = false;

  SpeakerMonitor monitor({Duration retry = const Duration(minutes: 1)}) => SpeakerMonitor(
        retryDelay: retry,
        fetch: () async => snap,
        changed: changed.stream,
        seen: seen.stream,
        active: () async => active,
        request: () async {
          requests++;
          return requestResult;
        },
      );

  void connect(List<BluetoothOutput> o, {bool permission = true}) =>
      snap = BluetoothSnapshot(permission: permission, outputs: o);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('estimate: speaker classes yes, the rest no', () {
    for (final c in [0x0414, 0x041C, 0x0428]) {
      expect(estimateSpeaker(c), isTrue, reason: '$c');
    }
    // headset, handsfree, headphones, car audio, phone, no class
    for (final c in [0x0404, 0x0408, 0x0418, 0x0420, 0x0200, null]) {
      expect(estimateSpeaker(c), isFalse, reason: '$c');
    }
  });

  test('connected follows the answer, else the estimate; events only on change', () async {
    final r = _Rig();
    final m = r.monitor();
    final events = <bool>[];
    m.speakerConnected.listen(events.add);
    await m.start();
    expect(m.connected, isFalse);

    r.connect([_out('a', 0x0414)]);
    r.changed.add(null);
    await _settle();
    expect(m.connected, isTrue);
    r.changed.add(null); // same state again
    await _settle();

    await m.answer('a', false); // the user says no, against the estimate
    expect(m.connected, isFalse);
    r.connect([_out('b', 0x0418)]);
    await m.answer('b', true); // headphones marked as speaker
    expect(m.connected, isTrue);
    await _settle();
    expect(events, [true, false, true]);
  });

  test('asks once per address, and again only after it went away unanswered', () async {
    final r = _Rig()..connect([_out('a', 0x0414, 'JBL')]);
    final m = r.monitor();
    final asked = <String>[];
    m.prompts.listen((p) => asked.add((p as AskPrompt).output.address));
    await m.start(); // already connected at opening
    await m.refresh();
    await _settle();
    expect(asked, ['a']);

    r.connect([]);
    await m.refresh();
    r.connect([_out('a', 0x0414, 'JBL')]);
    await m.refresh();
    await _settle();
    expect(asked, ['a', 'a']);

    await m.answer('a', true);
    r.connect([]);
    await m.refresh();
    r.connect([_out('a', 0x0414, 'JBL')]);
    await m.refresh();
    await _settle();
    expect(asked.length, 2, reason: 'answered: never asked again');
  });

  test('the answer, the switch and the name survive a restart', () async {
    final r = _Rig()..connect([_out('a', 0x0418, 'Cuffie')]);
    final m = r.monitor();
    await m.start();
    await m.answer('a', true);
    await m.setEnabled(false);

    final m2 = r.monitor();
    await m2.start();
    expect(m2.enabled, isFalse);
    expect(m2.answers['a']!.isSpeaker, isTrue);
    expect(m2.answers['a']!.name, 'Cuffie');
    expect(m2.connected, isTrue);
  });

  test('permission sheet: first seen output only, and only if never asked', () async {
    final r = _Rig()..connect([], permission: false);
    final m = r.monitor();
    var shown = 0;
    m.prompts.listen((p) {
      if (p is PermissionPrompt) shown++;
    });
    await m.start();
    r.seen.add(null);
    r.seen.add(null);
    await _settle();
    await _settle();
    expect(shown, 1);

    await m.declinePermission();
    final m2 = r.monitor();
    var again = 0;
    m2.prompts.listen((_) => again++);
    await m2.start();
    r.seen.add(null);
    await _settle();
    await _settle();
    expect(again, 0);
    expect(m2.permissionAsked, isTrue);
    expect(r.requests, 0);
  });

  test('allow asks the system and saves «asked»', () async {
    final r = _Rig()..connect([], permission: false);
    final m = r.monitor();
    await m.start();
    expect(await m.askPermission(), isTrue);
    expect(r.requests, 1);
    expect(m.permissionAsked, isTrue);
  });

  test('no permission seen: no prompt when it is already granted', () async {
    final r = _Rig();
    final m = r.monitor();
    var shown = 0;
    m.prompts.listen((p) {
      if (p is PermissionPrompt) shown++;
    });
    await m.start();
    r.seen.add(null);
    await _settle();
    expect(shown, 0);
  });

  test('a prompt raised before anyone listens is delivered once to the first listener', () async {
    final r = _Rig()..connect([_out('a', 0x0414, 'JBL')]);
    final m = r.monitor();
    await m.start(); // nobody listening yet
    expect(m.pending, hasLength(1));
    final first = <SpeakerPrompt>[];
    m.prompts.listen(first.add);
    await _settle();
    expect(first.single, isA<AskPrompt>());
    final second = <SpeakerPrompt>[];
    m.prompts.listen(second.add);
    await _settle();
    expect(second, isEmpty);
    expect(m.pending, isEmpty);
  });

  test('lost «seen» event: an active output at start offers the permission once', () async {
    final r = _Rig()
      ..connect([], permission: false)
      ..active = true;
    final m = r.monitor();
    await m.start();
    await m.refresh();
    expect(m.pending.whereType<PermissionPrompt>(), hasLength(1));

    r.active = false;
    final m2 = (_Rig()..connect([], permission: false)).monitor();
    await m2.start();
    expect(m2.pending, isEmpty);
  });

  test('refresh racing dispose does not throw', () async {
    final r = _Rig()..connect([_out('a', 0x0414)]);
    final m = r.monitor();
    await m.start();
    final pending = m.refresh();
    m.dispose();
    await pending;
  });

  test('a dismissed question comes back at the next opening, not on each change', () async {
    final r = _Rig()..connect([_out('a', 0x0414, 'JBL')]);
    final m = r.monitor();
    final asked = <SpeakerPrompt>[];
    m.prompts.listen(asked.add);
    await m.start();
    await _settle();
    expect(asked, hasLength(1));

    m.dismissed('a');
    r.changed.add(null); // a connection change while the app stays open
    await _settle();
    expect(asked, hasLength(1));

    await m.refresh(); // the app is opened again
    await _settle();
    expect(asked, hasLength(2));
  });

  test('a failed read keeps the speaker connected and emits nothing', () async {
    final r = _Rig()..connect([_out('a', 0x0414)]);
    final m = r.monitor();
    final events = <bool>[];
    m.speakerConnected.listen(events.add);
    await m.start();
    expect(m.connected, isTrue);
    r.snap = const BluetoothSnapshot(permission: true, ok: false);
    r.changed.add(null);
    await _settle();
    expect(m.connected, isTrue);
    expect(events, [true]);
  });

  test('overlapping reads: the older one finishing last is discarded', () async {
    final first = Completer<BluetoothSnapshot>();
    var calls = 0;
    final changed = StreamController<void>.broadcast();
    final m = SpeakerMonitor(
      fetch: () => ++calls == 1
          ? first.future
          : Future.value(BluetoothSnapshot(permission: true, outputs: [_out('a', 0x0414)])),
      changed: changed.stream,
      seen: const Stream.empty(),
      active: () async => false,
      request: () async => true,
    );
    final started = m.start(); // read 1 hangs
    await _settle();
    changed.add(null); // read 2 answers at once: speaker connected
    await _settle();
    expect(m.connected, isTrue);
    first.complete(const BluetoothSnapshot(permission: true)); // stale: nothing connected
    await started;
    expect(m.connected, isTrue);
  });

  test('an older ok read finishing after a newer failed one is applied', () async {
    final first = Completer<BluetoothSnapshot>();
    var calls = 0;
    final changed = StreamController<void>.broadcast();
    final m = SpeakerMonitor(
      fetch: () => ++calls == 1
          ? first.future
          : Future.value(const BluetoothSnapshot(permission: true, ok: false)),
      changed: changed.stream,
      seen: const Stream.empty(),
      active: () async => false,
      request: () async => true,
      retryDelay: const Duration(minutes: 1),
    );
    final started = m.start();
    await _settle();
    changed.add(null); // read 2 fails
    await _settle();
    first.complete(BluetoothSnapshot(permission: true, outputs: [_out('a', 0x0414)]));
    await started;
    expect(m.connected, isTrue);
    m.dispose();
  });

  test('answer applies even when the read fails; a failed read is retried once', () async {
    final r = _Rig()..connect([_out('a', 0x0200)]);
    final m = r.monitor(retry: const Duration(milliseconds: 20));
    await m.start();
    expect(m.connected, isFalse);
    var changes = 0;
    m.changes.listen((_) => changes++);
    r.snap = const BluetoothSnapshot(permission: true, ok: false);
    await m.answer('a', true);
    await _settle();
    expect(m.connected, isTrue);
    expect(changes, greaterThan(0));
    // the retry finds the real state: the device is gone
    r.snap = const BluetoothSnapshot(permission: true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(m.connected, isFalse);
    m.dispose();
  });
}
