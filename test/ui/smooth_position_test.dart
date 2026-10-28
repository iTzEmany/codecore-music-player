import 'package:codecore/ui/widgets/smooth_position.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Owns a [SmoothPosition] on the test clock so tests can drive it.
class _Host extends StatefulWidget {
  const _Host({required this.p});

  final SmoothPosition p;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.p.bindTickerMode(context);
  }

  @override
  void dispose() {
    widget.p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  late SmoothPosition p;
  late List<Duration> seen;

  Future<void> pump(WidgetTester tester, {bool tickerMode = true}) async {
    final t0 = tester.binding.clock.now();
    p = SmoothPosition(uptime: () => tester.binding.clock.now().difference(t0));
    await tester.pumpWidget(
      TickerMode(
        enabled: tickerMode,
        child: _Host(p: p),
      ),
    );
    seen = [];
    p.addListener(() => seen.add(p.value));
  }

  // Disposes the host, which cancels the timer.
  Future<void> end(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  testWidgets('paused: no update in 2 s', (tester) async {
    await pump(tester);
    p.update(const Duration(seconds: 5), playing: false);
    seen.clear();
    await tester.pump(const Duration(seconds: 2));
    expect(seen, isEmpty);
    expect(p.value, const Duration(seconds: 5));
    await end(tester);
  });

  testWidgets('playing: advances 10 times a second, monotonic, no frames', (
    tester,
  ) async {
    await pump(tester);
    p.update(const Duration(seconds: 5), playing: true);
    seen.clear();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(seen, hasLength(20));
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i] - seen[i - 1], const Duration(milliseconds: 100));
    }
    expect(p.value, const Duration(seconds: 7));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await end(tester);
  });

  testWidgets('a new fact re-anchors, a pause freezes, duration caps', (
    tester,
  ) async {
    await pump(tester);
    p.update(Duration.zero, playing: true);
    await tester.pump(const Duration(seconds: 2));
    p.update(const Duration(seconds: 30), playing: true);
    expect(p.value, const Duration(seconds: 30));
    p.update(
      const Duration(seconds: 58),
      playing: true,
      duration: const Duration(minutes: 1),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(p.value, const Duration(minutes: 1));
    p.update(const Duration(seconds: 31), playing: false);
    seen.clear();
    await tester.pump(const Duration(seconds: 2));
    expect(seen, isEmpty);
    expect(p.value, const Duration(seconds: 31));
    await end(tester);
  });

  testWidgets('covered route (TickerMode off): silent, then catches up', (
    tester,
  ) async {
    await pump(tester, tickerMode: false);
    p.update(const Duration(seconds: 5), playing: true);
    seen.clear();
    await tester.pump(const Duration(seconds: 2));
    expect(seen, isEmpty);
    await tester.pumpWidget(TickerMode(enabled: true, child: _Host(p: p)));
    expect(p.value, const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 100));
    expect(seen.last, const Duration(milliseconds: 7100));
    await end(tester);
  });
}
