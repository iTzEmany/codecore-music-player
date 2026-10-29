import 'dart:async';

import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/speaker_jam.dart';
import 'package:flutter_test/flutter_test.dart';

class _Port implements SpeakerJamPort {
  @override
  SpeakerJamView view = const SpeakerJamView();
  final _c = StreamController<void>.broadcast();
  final log = <String>[];

  Future<void> set(SpeakerJamView v) async {
    view = v;
    _c.add(null);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<void> get changes => _c.stream;
  @override
  Future<void> open() async => log.add('open');
  @override
  Future<void> closeSilently() async => log.add('close');
  @override
  Future<void> send(JamCommand cmd) async => log.add(cmd.type.name);
  @override
  Future<void> end() async => log.add('end');
}

void main() {
  late _Port port;
  late StreamController<bool> conn;
  var connected = false, enabled = true;
  final timers = <(Duration, void Function(), _FakeTimer)>[];

  SpeakerJam make() => SpeakerJam(
        speakerConnected: conn.stream,
        connected: () => connected,
        enabled: () => enabled,
        port: port,
        timer: (d, f) {
          final t = _FakeTimer();
          timers.add((d, f, t));
          return t;
        },
      );

  Future<void> plug(bool v) async {
    connected = v;
    conn.add(v);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  const host = SpeakerJamView(role: SpeakerRole.host, speaker: true);
  const hostWith = SpeakerJamView(role: SpeakerRole.host, speaker: true, guests: 1);

  setUp(() {
    port = _Port();
    conn = StreamController<bool>.broadcast();
    connected = false;
    enabled = true;
    timers.clear();
  });

  test('a speaker connects while enabled: the Jam opens once', () async {
    final s = make();
    await plug(true);
    await plug(true);
    expect(port.log, ['open']);
    s.dispose();
  });

  test('switched off: nothing opens', () async {
    enabled = false;
    final s = make();
    await plug(true);
    expect(port.log, isEmpty);
    s.dispose();
  });

  test('the speaker goes with nobody in the Jam: closes silently', () async {
    connected = true;
    port.view = host;
    final s = make();
    await plug(false);
    expect(port.log, ['close']);
    s.dispose();
  });

  test('the speaker goes with guests: speakerAway, then the Jam ends after 10 minutes', () async {
    connected = true;
    port.view = hostWith;
    final s = make();
    await plug(false);
    expect(port.log, ['speakerAway']);
    await port.set(const SpeakerJamView(
        role: SpeakerRole.host, speaker: true, guests: 1, awaySince: 5));
    expect(timers.single.$1, const Duration(minutes: 10));
    timers.single.$2();
    expect(port.log, ['speakerAway', 'end']);
    s.dispose();
  });

  test('the speaker is back before 10 minutes: speakerBack and no end', () async {
    connected = true;
    port.view = hostWith;
    final s = make();
    await plug(false);
    await port.set(const SpeakerJamView(
        role: SpeakerRole.host, speaker: true, guests: 1, awaySince: 5));
    await plug(true);
    expect(port.log, ['speakerAway', 'speakerBack']);
    await port.set(hostWith);
    expect(timers.single.$3.cancelled, isTrue);
    s.dispose();
  });

  test('away set by another way while our speaker is there: speakerBack (D-220)', () async {
    connected = true;
    port.view = hostWith;
    final s = make();
    await port.set(const SpeakerJamView(
        role: SpeakerRole.host, speaker: true, guests: 0, awaySince: 5));
    await pump();
    expect(port.log, ['speakerBack']);
    s.dispose();
  });

  test('away without our speaker (the output guest left): the timer starts', () async {
    connected = false;
    port.view = hostWith;
    final s = make();
    await port.set(const SpeakerJamView(
        role: SpeakerRole.host, speaker: true, guests: 0, awaySince: 5));
    expect(timers, hasLength(1));
    s.dispose();
  });

  test('switched off with nobody in the speaker Jam: closes; with guests: nothing', () async {
    connected = true;
    port.view = host;
    final s = make();
    enabled = false;
    s.refresh();
    expect(port.log, ['close']);
    port.log.clear();
    port.view = hostWith;
    s.refresh();
    expect(port.log, isEmpty);
    s.dispose();
  });

  group('guest', () {
    const away = SpeakerJamView(role: SpeakerRole.guest, speaker: true, awaySince: 5);

    test('offer only while the Jam is stopped and our speaker is there', () async {
      connected = true;
      port.view = const SpeakerJamView(role: SpeakerRole.guest, speaker: true);
      final s = make();
      expect(s.offerPending.value, isFalse);
      await port.set(away);
      expect(s.offerPending.value, isTrue);
      await s.acceptOffer();
      expect(port.log, ['offerSpeaker']);
      expect(s.offerPending.value, isFalse);
      s.dispose();
    });

    test('no offer without our speaker; declining silences this absence only', () async {
      connected = false;
      port.view = away;
      final s = make();
      expect(s.offerPending.value, isFalse);
      await plug(true);
      expect(s.offerPending.value, isTrue);
      s.declineOffer();
      await port.set(away);
      expect(s.offerPending.value, isFalse);
      await port.set(const SpeakerJamView(role: SpeakerRole.guest, speaker: true));
      await port.set(const SpeakerJamView(role: SpeakerRole.guest, speaker: true, awaySince: 9));
      expect(s.offerPending.value, isTrue);
      s.dispose();
    });

    test('the guest that is the output loses its speaker: speakerAway once', () async {
      connected = true;
      port.view = const SpeakerJamView(
          role: SpeakerRole.guest, speaker: true, iAmOutput: true);
      final s = make();
      await plug(false);
      await port.set(port.view);
      expect(port.log, ['speakerAway']);
      s.dispose();
    });
  });
}

class _FakeTimer implements Timer {
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}
