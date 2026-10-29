import 'dart:convert';

import 'package:codecore/data/settings/jam_secret_store.dart';
import 'package:codecore/services/jam/jam_gate.dart';
import 'package:codecore/services/jam/jam_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late Map<String, String> data;
  late JamGate gate;

  // "Restart": a new gate over the same map.
  Future<JamGate> open() async {
    final g = JamGate(MemoryJamSecretStore(data), now: () => now);
    await g.ready;
    return g;
  }

  setUp(() async {
    now = DateTime(2026, 1, 1, 12);
    data = {};
    gate = await open();
  });

  test('2 per minute per id, sliding window', () {
    expect(gate.allow('a'), isTrue);
    now = now.add(const Duration(seconds: 10));
    expect(gate.allow('a'), isTrue);
    expect(gate.allow('a'), isFalse);
    expect(gate.allow('b'), isTrue);
    now = now.add(const Duration(seconds: 50));
    expect(gate.allow('a'), isTrue); // the first one left the window
  });

  test('suspend 15 min survives a restart and expires', () async {
    gate.suspend('a', 'Phone', const Duration(minutes: 15));
    expect(gate.isMuted('a'), isTrue);
    gate = await open();
    now = now.add(const Duration(minutes: 15));
    expect(gate.isMuted('a'), isTrue);
    now = now.add(const Duration(seconds: 1));
    expect(gate.isMuted('a'), isFalse);
    expect(gate.suspended, isEmpty);
  });

  test('suspension until the end of the Jam is dropped at the end and at start', () async {
    gate.suspend('a', 'A', null);
    gate.suspend('b', 'B', null);
    gate.clearEndOfJam();
    expect(gate.isMuted('a'), isFalse);
    gate.suspend('c', 'C', null);
    gate = await open();
    expect(gate.isMuted('c'), isFalse);
  });

  test('block and unblock persist across restarts', () async {
    gate.block('a', 'Phone');
    gate = await open();
    expect(gate.isMuted('a'), isTrue);
    expect(gate.blocked.single.name, 'Phone');
    gate.unblock('a');
    gate = await open();
    expect(gate.isMuted('a'), isFalse);
  });

  group('admitRequest', () {
    late JamHost h;
    final seen = <String>[];
    Map<String, Object?> body(String id) =>
        {'fromId': id, 'fromName': 'P', 'port': 4000, 'token': 'tok-12345'};

    setUp(() {
      seen.clear();
      h = JamHost(deviceId: 'h', deviceName: 'PC', now: () => now, gate: gate)
        ..onRequest = (r) => seen.add(r.fromId);
    });

    test('silent request: 202, not shown, not busy, expires', () async {
      gate.suspend('s', 'S', null);
      final r = h.admitRequest(body('s'));
      expect(r.statusCode, 202);
      expect(jsonDecode(await r.readAsString())['requestId'], isNotNull);
      expect(seen, isEmpty);
      expect(h.admitRequest(body('ok')).statusCode, 202); // not busy
      expect(seen, ['ok']);
      final silent = h.requests.values.firstWhere((q) => q.silent);
      now = now.add(jamRequestTtl + const Duration(seconds: 1));
      h.expire();
      expect(silent.status, JamRequestStatus.expired);
    });

    test('third request in a minute from the same id is 429', () {
      for (var i = 0; i < 2; i++) {
        expect(h.admitRequest(body('a')).statusCode, 202);
        h.decline(h.requests.values.last.id);
      }
      expect(h.admitRequest(body('a')).statusCode, 429);
    });
  });
}
