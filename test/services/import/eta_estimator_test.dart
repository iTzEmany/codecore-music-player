import 'package:codecore/services/import/eta_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var clock = DateTime(2026, 10, 16, 12);
  void advance(int seconds) => clock = clock.add(Duration(seconds: seconds));
  EtaEstimator make() => EtaEstimator(now: () => clock);

  setUp(() => clock = DateTime(2026, 10, 16, 12));

  test('no estimate before 3 samples', () {
    final e = make()..start();
    advance(10);
    e.rowDone();
    advance(10);
    e.rowDone();
    expect(e.remaining(5), isNull);
    advance(10);
    e.rowDone();
    expect(e.remaining(5), const Duration(seconds: 50));
  });

  test('a steady pace gives pace × rows left', () {
    final e = make()..start();
    for (var i = 0; i < 6; i++) {
      advance(8);
      e.rowDone();
    }
    expect(e.remaining(10), const Duration(seconds: 80));
    expect(e.remaining(0), isNull);
  });

  test('recent rows weigh more than old ones', () {
    final e = make()..start();
    for (var i = 0; i < 3; i++) {
      advance(10);
      e.rowDone();
    }
    for (var i = 0; i < 5; i++) {
      advance(30);
      e.rowDone();
    }
    final perRow = e.remaining(1)!.inSeconds;
    expect(perRow, greaterThan(20));
    expect(perRow, lessThan(30));
  });

  test('rows linked from the library do not count as samples', () {
    final e = make()..start();
    for (var i = 0; i < 50; i++) {
      advance(0);
      e.rowDone(linked: true);
    }
    expect(e.samples, 0);
    expect(e.remaining(10), isNull);
    for (var i = 0; i < 3; i++) {
      advance(12);
      e.rowDone();
    }
    expect(e.remaining(10), const Duration(seconds: 120));
  });

  test('a long pause does not inflate the average', () {
    final e = make()..start();
    for (var i = 0; i < 4; i++) {
      advance(10);
      e.rowDone();
    }
    e.pause();
    advance(3600);
    e.start();
    advance(10);
    e.rowDone();
    expect(e.remaining(1), const Duration(seconds: 10));
  });

  test('the first row after a pause without start() is ignored', () {
    final e = make()..start();
    for (var i = 0; i < 3; i++) {
      advance(10);
      e.rowDone();
    }
    e.pause();
    advance(7200);
    e.rowDone();
    expect(e.samples, 3);
    expect(e.remaining(1), const Duration(seconds: 10));
  });
}
