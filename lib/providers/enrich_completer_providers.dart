import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../core/clock.dart';
import '../data/db/app_database.dart';
import '../services/online/enrich_completer.dart';
import '../services/online/enrich_parts.dart';
import 'activity_log_providers.dart';
import 'activity_providers.dart';
import 'database_providers.dart';
import 'online_providers.dart';
import 'settings_providers.dart';
import 'user_activity_provider.dart';

/// How long the user must leave the app alone before the next track.
const _idleFor = Duration(seconds: 5);

class EnrichCompleterState {
  const EnrichCompleterState({
    this.running = false,
    this.paused = false,
    this.manual = false,
    this.complete = 0,
    this.total = 0,
  });

  /// A run is going (also while it finishes the track in hand after a pause).
  final bool running;

  /// Stopped by hand until «Riprendi» (or the next start of the app).
  final bool paused;

  /// Started with «Completa l'arricchimento» (no waiting for the user).
  final bool manual;

  /// Tracks with nothing left to ask, and all of them; moves every 10 tracks.
  final int complete, total;

  /// Shown in the Activity centre.
  bool get visible => running || paused;

  EnrichCompleterState copyWith({
    bool? running,
    bool? paused,
    bool? manual,
    int? complete,
    int? total,
  }) => EnrichCompleterState(
    running: running ?? this.running,
    paused: paused ?? this.paused,
    manual: manual ?? this.manual,
    complete: complete ?? this.complete,
    total: total ?? this.total,
  );
}

/// Completes the library in the background while the app is open (D-102).
/// A pause is a stop of the run: its line goes to the Registro, and «Riprendi»
/// starts the next run where the database says (the state is all there).
class EnrichCompleterNotifier extends Notifier<EnrichCompleterState> {
  /// How often a waiting run looks at the user again.
  Duration poll = const Duration(seconds: 1);

  Future<void>? _current;
  bool _halt = false, _again = false;

  EnrichCompleter? _built;

  // Built on the first run: it needs the whole enrichment service.
  EnrichCompleter get _completer => _built ??= EnrichCompleter(
    service: ref.read(enrichmentServiceProvider),
    repo: ref.read(creditsRepositoryProvider),
    parts: () => autoParts(ref.read(settingsProvider)),
    waitIdle: _waitIdle,
    onProgress: (c, t) {
      if (ref.mounted) state = state.copyWith(complete: c, total: t);
    },
  );

  @override
  EnrichCompleterState build() {
    ref.onDispose(() {
      _halt = true;
      _built?.cancel();
    });
    return const EnrichCompleterState();
  }

  /// Set by [enrichCompleterStartProvider]: reading the provider from here
  /// would close a cycle (the activity list watches this notifier, the busy
  /// flag listens to the activity list). Without it nothing waits.
  UserActivity? activity;

  Future<void> _waitIdle() async {
    while (!_halt && !(activity?.idleFor(_idleFor) ?? true)) {
      await Future<void>.delayed(poll);
    }
  }

  /// A run until nothing is due. Does nothing while paused by hand or when
  /// everything is complete. Called during a run (a switch changed, a scan
  /// ended) it asks for another one when this ends.
  Future<void> start({bool now = false}) {
    if (state.paused && !now) return Future.value();
    final current = _current;
    if (current != null) {
      _again = true;
      return current;
    }
    return _current = _go(now).whenComplete(() {
      _current = null;
      if (_again && ref.mounted) {
        _again = false;
        unawaited(start());
      }
    });
  }

  Future<void> _go(bool now) async {
    _halt = false;
    try {
      final c = await ref
          .read(creditsRepositoryProvider)
          .enrichCounts(
            autoParts(ref.read(settingsProvider)),
            DateTime.fromMillisecondsSinceEpoch(nowMs()),
          );
      if (_halt || !ref.mounted) return; // stopped while counting
      if (!now && c.complete >= c.total) return;
      state = EnrichCompleterState(
        running: true,
        manual: now,
        complete: c.complete,
        total: c.total,
      );
      final round = await _completer.run(now: now);
      if (round.worked > 0) await _log(round, stopped: _halt, failed: round.failed);
    } on Object catch (e, st) {
      AppLog.w('completion failed', e, st);
    } finally {
      if (ref.mounted) state = state.copyWith(running: false);
    }
  }

  /// «Completa l'arricchimento»: now, whatever the user is doing. A run in
  /// progress turns into this one (its line goes to the Registro as one).
  Future<void> runNow() async {
    state = state.copyWith(paused: false);
    if (state.running && !_halt) {
      state = state.copyWith(manual: true);
      _completer.run(now: true).ignore(); // joins the run; _go logs its errors
      await _current;
      return;
    }
    _halt = true; // a run still counting stops at its next look
    await _current; // a stopped run is still ending
    await start(now: true);
  }

  /// Stops after the track in hand until [resume]. The Registro gets the
  /// line of the round so far.
  void pause() {
    if (!state.running) return;
    state = state.copyWith(paused: true);
    _halt = true;
    _completer.cancel();
  }

  Future<void> resume() async {
    if (!state.paused) return;
    await _current; // the run that was paused may still be ending
    if (!state.paused) return; // «Interrompi» or «Completa» came first
    state = state.copyWith(paused: false);
    unawaited(start());
  }

  /// «Interrompi»: no track after the one in hand; the next start of the app
  /// (or a change of the switches) carries on.
  void cancel() {
    state = state.copyWith(paused: false);
    _halt = true;
    _again = false;
    if (_current != null) _completer.cancel();
  }

  Future<void> _log(
    EnrichRound round, {
    required bool stopped,
    required bool failed,
  }) {
    Set<int> ids(Map<EnrichPart, List<int>> m) => {for (final l in m.values) ...l};
    Map<String, List<int>> byPart(Map<EnrichPart, List<int>> m) => {
      for (final e in m.entries) e.key.name: e.value,
    };
    return ref
        .read(activityLogProvider.notifier)
        .add(
          LogEntry(
            at: DateTime.now(),
            item: ActivityItem(
              kind: ActivityKind.enrichBackground,
              key: 'enrichBackground-${DateTime.now().microsecondsSinceEpoch}',
              name: null,
              // Tracks that got something, tracks that were asked in vain.
              done: ids(round.updated).length,
              total: ids(round.none).length,
              running: false,
              failed: failed,
            ),
            detail: {
              if (stopped) 'stopped': true,
              'updated': byPart(round.updated),
              'none': byPart(round.none),
            },
          ),
        );
  }
}

final enrichCompleterProvider =
    NotifierProvider<EnrichCompleterNotifier, EnrichCompleterState>(
      EnrichCompleterNotifier.new,
    );

typedef EnrichRoundRow = ({EnrichPart part, Track track});

/// The two groups of a round line of the Registro.
class EnrichRoundView {
  const EnrichRoundView(this.updated, this.none);

  final List<EnrichRoundRow> updated, none;
}

/// The tracks behind a round line of the Registro, from its `detail`. A track
/// deleted since is left out.
final enrichRoundProvider = FutureProvider.autoDispose
    .family<EnrichRoundView, LogEntry>((ref, entry) async {
      final tracks = ref.watch(trackRepositoryProvider);
      Future<List<EnrichRoundRow>> group(String key) async {
        final raw = entry.detail?[key];
        if (raw is! Map) return const [];
        return [
          for (final part in EnrichPart.values)
            if (raw[part.name] case final List ids)
              for (final t in await tracks.getByIdsLight([
                for (final i in ids)
                  if (i is int) i,
              ]))
                (part: part, track: t),
        ];
      }

      return EnrichRoundView(await group('updated'), await group('none'));
    });
