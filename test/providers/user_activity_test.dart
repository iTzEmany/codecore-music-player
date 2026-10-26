import 'package:codecore/providers/activity_providers.dart';
import 'package:codecore/providers/user_activity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Running extends Notifier<ActivityState> {
  @override
  ActivityState build() => const ActivityState([], []);

  void set(ActivityState s) => state = s;
}

void main() {
  var t = DateTime(2026);
  setUp(() => t = DateTime(2026));

  test('touch makes the user busy for the window, then idle', () {
    final a = UserActivity(now: () => t);
    expect(a.idleFor(const Duration(seconds: 5)), isTrue);
    a.touch();
    t = t.add(const Duration(seconds: 4));
    expect(a.idleFor(const Duration(seconds: 5)), isFalse);
    t = t.add(const Duration(seconds: 1));
    expect(a.idleFor(const Duration(seconds: 5)), isTrue);
  });

  test('a busy spell blocks until it ends, then 5 s more', () {
    final a = UserActivity(now: () => t);
    a.busy = true;
    t = t.add(const Duration(minutes: 10));
    expect(a.idleFor(const Duration(seconds: 5)), isFalse);
    a.busy = false;
    expect(a.idleFor(const Duration(seconds: 5)), isFalse);
    t = t.add(const Duration(seconds: 5));
    expect(a.idleFor(const Duration(seconds: 5)), isTrue);
  });

  test('waitIdle returns once the window has passed', () async {
    final a = UserActivity(now: () => t);
    a.touch();
    var done = false;
    final w = a
        .waitIdle(const Duration(seconds: 5), poll: const Duration(milliseconds: 1))
        .then((_) => done = true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(done, isFalse);
    t = t.add(const Duration(seconds: 5));
    await w;
    expect(done, isTrue);
  });

  test(
    'download, import, transfer, scan and enrichment in progress set busy; the background completion does not',
    () async {
      final notifier = NotifierProvider<_Running, ActivityState>(_Running.new);
      final c = ProviderContainer(
        overrides: [
          activityProvider.overrideWith((ref) => ref.watch(notifier)),
        ],
      );
      addTearDown(c.dispose);
      final a = c.listen(userActivityProvider, (_, _) {}).read();
      Future<void> set(ActivityState s) async {
        c.read(notifier.notifier).set(s);
        await Future<void>.delayed(Duration.zero);
      }

      ActivityState of(ActivityKind k) => ActivityState([
        ActivityItem(kind: k, key: 'k', name: null),
      ], const []);
      expect(a.isBusy, isFalse);
      await set(of(ActivityKind.enrichBackground));
      expect(a.isBusy, isFalse);
      await set(
        const ActivityState([
          ActivityItem(
            kind: ActivityKind.import,
            key: 'p',
            name: null,
            paused: true,
          ),
        ], []),
      );
      expect(a.isBusy, isFalse);
      for (final k in [
        ActivityKind.download,
        ActivityKind.import,
        ActivityKind.transfer,
        ActivityKind.scan,
        ActivityKind.enrich,
      ]) {
        await set(of(k));
        expect(a.isBusy, isTrue, reason: '$k');
        await set(const ActivityState([], []));
        expect(a.isBusy, isFalse);
      }
      expect(a.lastActivityAt, isNotNull);
    },
  );
}
