import 'dart:async';

import '../../core/clock.dart';
import '../../data/repositories/credits_repository.dart';
import 'enrich_engine.dart';
import 'enrich_parts.dart';
import 'enrich_runner.dart';

export 'enrich_runner.dart' show EnrichRound;

/// Completes the library in the background: one [EnrichRunner] at a time,
/// over the library from the bookmark. The state lives in the database, so a
/// new run simply carries on where the last one stopped.
class EnrichCompleter {
  EnrichCompleter({
    required this.engine,
    required this.repo,
    required this.parts,
    required this.waitIdle,
    this.onProgress,
    this.onWaiting,
    this.loadMark,
    this.saveMark,
    int Function()? nowMs,
  }) : _nowMs = nowMs ?? _clock;

  static int _clock() => nowMs();

  final EnrichEngine engine;
  final CreditsRepository repo;

  /// The parts the switches turn on, read at each chunk.
  final Set<EnrichPart> Function() parts;

  /// Completes when the user leaves the app alone (and no pause is on).
  final Future<void> Function() waitIdle;

  /// After each committed block: tracks complete, tracks in all.
  final void Function(int complete, int total)? onProgress;

  /// See [EnrichRunner.onWaiting].
  final void Function(bool waiting)? onWaiting;

  /// Bookmark: the last track tried, so a run starts after it. Without them
  /// every run starts from the first track.
  final int Function()? loadMark;
  final void Function(int id)? saveMark;
  final int Function() _nowMs;

  EnrichRunner? _runner;
  Future<EnrichRound>? _current;

  bool get running => _current != null;

  /// The request in flight is aborted (that track is not tried, the bookmark
  /// stays before it), no track is started, and a wait for the user ends at once.
  void cancel() => _runner?.cancel();

  /// One run until nothing is due, [cancel] or an error. Called during a run
  /// it joins it: the same future comes back.
  Future<EnrichRound> run() {
    final current = _current;
    if (current != null) return current;
    final runner = _runner = EnrichRunner(
      engine: engine,
      ids: MarkCursor(repo, load: loadMark, save: saveMark),
      parts: parts,
      waitIdle: waitIdle,
      onProgress: onProgress,
      onWaiting: onWaiting,
      nowMs: _nowMs,
    );
    return _current = runner.run().whenComplete(() {
      _current = null;
      _runner = null;
    });
  }
}
