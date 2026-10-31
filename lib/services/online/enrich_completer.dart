import 'dart:async';

import '../../core/app_log.dart';
import '../../core/clock.dart';
import '../../data/repositories/credits_repository.dart';
import 'enrichment_service.dart';

/// What one run of [EnrichCompleter] did: tracks worked, and the ids that got
/// something (`updated`) or were asked with an empty answer (`none`), per part.
class EnrichRound {
  int worked = 0;

  /// The run stopped on an error (logged), lost a write (a track or a whole
  /// block not saved) or stopped with [noAnswer]: the rest of the library waits
  /// for the next run; what was read before it is written and counted here.
  bool failed = false;

  /// The run stopped because the sources answered none of the last tracks.
  bool noAnswer = false;
  final Map<EnrichPart, List<int>> updated = {};
  final Map<EnrichPart, List<int>> none = {};
}

/// Completes the library in the background: tracks with a part that is on and
/// due, one at a time, their writes gathered into one transaction every
/// [blockSize] tracks. No Riverpod; the state lives in the database, so a new
/// run simply carries on where the last one stopped.
class EnrichCompleter {
  EnrichCompleter({
    required this.service,
    required this.repo,
    required this.parts,
    required this.waitIdle,
    this.onProgress,
    this.loadMark,
    this.saveMark,
    int Function()? nowMs,
  }) : _nowMs = nowMs ?? _clock;

  static int _clock() => nowMs();

  static const blockSize = 10;
  static const _chunk = 20;
  static const _maxStuck = 5;

  final EnrichmentService service;
  final CreditsRepository repo;

  /// The parts the switches turn on, read at each chunk.
  final Set<EnrichPart> Function() parts;

  /// Completes when the user leaves the app alone (and no pause is on).
  final Future<void> Function() waitIdle;

  /// After each committed block: tracks complete, tracks in all.
  final void Function(int complete, int total)? onProgress;
  /// Bookmark: the last track tried, so a run starts after it. Without them
  /// every run starts from the first track.
  final int Function()? loadMark;
  final void Function(int id)? saveMark;
  final int Function() _nowMs;

  Future<EnrichRound>? _current;
  bool _cancelled = false, _now = false;
  int _saved = 0; // last bookmark handed to saveMark in this round
  Completer<void>? _wake;

  bool get running => _current != null;

  /// No track is started after the one in progress, and a wait for the user
  /// ends at once.
  void cancel() {
    _cancelled = true;
    _poke();
  }

  void _poke() {
    final w = _wake;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// One run until nothing is due, [cancel] or an error. [now]: no waiting for
  /// the user, and parts marked «nothing» recently are asked again (still only
  /// if empty). Called during a run it joins it: the same future comes back,
  /// and `now` turns that run into a «now» one from the next track.
  Future<EnrichRound> run({bool now = false}) {
    final current = _current;
    if (current != null) {
      if (now && !_now) {
        _now = true;
        _poke();
      }
      return current;
    }
    _now = now;
    _cancelled = false;
    return _current = _run().whenComplete(() => _current = null);
  }

  /// Waits for the user to leave the app alone, or for [cancel] / a switch to «now».
  Future<void> _idle() async {
    final wake = _wake = Completer<void>();
    await Future.any([waitIdle(), wake.future]);
    _wake = null;
  }

  Future<EnrichRound> _run() async {
    final round = EnrichRound();
    final tried = <int>{}; // a track that came out failed would be due again at once
    final refused = <EnrichPart>{}; // a source that said «too many requests»: not again in this round
    final block = <EnrichGather>[];
    var wanted = parts();
    var after = loadMark?.call() ?? 0;
    _saved = after;
    var canWrap = after > 0; // end of the queue: one pass from the start
    var stuck = 0; // tracks in a row that asked a source and got no answer (offline); one that asked nothing doesn't count
    Set<EnrichPart> switchedOn() => wanted = parts().difference(refused);
    try {
      try {
        while (!_cancelled && stuck < _maxStuck && switchedOn().isNotEmpty) {
          final ids = await repo.dueTrackIds(
            wanted,
            DateTime.fromMillisecondsSinceEpoch(_nowMs()),
            limit: _chunk,
            exclude: tried,
            ignoreMarks: _now,
            after: after,
          );
          if (ids.isEmpty) {
            if (!canWrap) break;
            canWrap = false;
            after = 0;
            continue;
          }
          for (final id in ids) {
            if (_cancelled) break;
            if (!_now) await _idle();
            await service.limiter.wait();
            if (_cancelled) break;
            // The switches may have changed since the chunk was read.
            if (switchedOn().isEmpty) break;
            tried.add(id);
            after = id;
            try {
              final g = await service.gather(id, wanted, ignoreMarks: _now);
              block.add(g);
              // A track whose parts were all refused meanwhile asked nothing: neither a sign of offline nor of life.
              final asked = g.out.values.any((o) => o != PartOutcome.skipped);
              if (g.answered) {
                stuck = 0;
              } else if (asked) {
                stuck++;
              }
              refused.addAll([
                for (final e in g.out.entries)
                  if (e.value == PartOutcome.limited) e.key,
              ]);
            } on Object catch (e, st) {
              if (e is Error) {
                AppLog.e('completion: track $id not read', e, st);
              } else {
                AppLog.w('completion: track $id not read', e, st);
              }
              stuck++;
            }
            if (stuck >= _maxStuck) {
              AppLog.w('completion: $_maxStuck tracks in a row got no answer, round stopped');
              round.failed = round.noAnswer = true;
              break;
            }
            if (block.length >= blockSize) await _commit(block, round, after);
          }
          await _commit(block, round, after);
        }
      } finally {
        // Whatever was read is written, also after an error or a cancel.
        await _commit(block, round, after);
      }
    } on Object catch (e, st) {
      if (e is Error) {
        AppLog.e('completion: round stopped', e, st);
      } else {
        AppLog.w('completion: round stopped', e, st);
      }
      round.failed = true;
    }
    return round;
  }

  Future<void> _commit(
    List<EnrichGather> block,
    EnrichRound round,
    int after,
  ) async {
    // Saved before the write and also when it fails (or every read threw), so a
    // bad block is not retried at each start; lost tracks come back after the wrap.
    if (after > 0 && after != _saved) {
      _saved = after;
      saveMark?.call(after);
    }
    if (block.isEmpty) return;
    final items = [...block];
    block.clear();
    try {
      final outs = await service.commit(items);
      if (items.any((g) => g.lost)) round.failed = true;
      for (var i = 0; i < items.length; i++) {
        final out = outs[i];
        if (!out.values.any((o) => o == PartOutcome.found || o == PartOutcome.none)) {
          continue;
        }
        round.worked++;
        for (final MapEntry(key: part, value: o) in out.entries) {
          final into = switch (o) {
            PartOutcome.found => round.updated,
            PartOutcome.none => round.none,
            _ => null,
          };
          into?.putIfAbsent(part, () => []).add(items[i].trackId);
        }
      }
    } on Object catch (e, st) {
      if (e is Error) {
        AppLog.e('completion: block of ${items.length} not saved', e, st);
      } else {
        AppLog.w('completion: block of ${items.length} not saved', e, st);
      }
      round.failed = true;
    }
    final c = await repo.enrichCounts(
      parts(),
      DateTime.fromMillisecondsSinceEpoch(_nowMs()),
    );
    onProgress?.call(c.complete, c.total);
  }
}
