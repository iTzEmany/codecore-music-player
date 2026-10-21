import 'dart:async';

import 'package:codecore/services/online/quiet_enricher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one song at a time, none lost while another runs', () async {
    final gates = <int, Completer<void>>{};
    final started = <int>[];
    final q = QuietEnricher(enrich: (id) {
      started.add(id);
      return (gates[id] = Completer<void>()).future;
    });
    final seen = <Set<int>>[];
    final sub = q.changes.listen(seen.add);
    q
      ..add(1)
      ..add(2)
      ..add(2); // twice: enriched once
    await Future<void>.delayed(Duration.zero);
    expect(started, [1]);
    expect(q.pending, {1, 2});
    gates[1]!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(started, [1, 2]);
    expect(q.pending, {2});
    gates[2]!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(q.pending, isEmpty);
    expect(seen.last, isEmpty);
    await sub.cancel();
    q.dispose();
  });

  test('a failure goes on with the next song; off = nothing is queued', () async {
    var on = true;
    final done = <int>[];
    final q = QuietEnricher(
      enabled: () => on,
      enrich: (id) async {
        if (id == 1) throw StateError('offline');
        done.add(id);
      },
    );
    q
      ..add(1)
      ..add(2);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(done, [2]);
    on = false;
    q.add(3);
    expect(q.pending, isEmpty);
    q.dispose();
  });
}
