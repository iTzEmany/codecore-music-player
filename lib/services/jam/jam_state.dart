import 'jam_models.dart';

/// Pure reducer for the authoritative Jam state (lives on the host).
///
/// [from] is the device id issuing the command; [nowMs] is the host clock.
/// Rules (docs/fase-8-jam.md): the guest can add, move, play/pause, seek,
/// volume and change the output device, but cannot change the current track
/// (`next`, `jump`, removing the current item) and cannot end the session
/// for the host's items; each participant removes their own items, the host
/// removes any.
JamResult applyCommand(
  JamState s,
  JamCommand cmd, {
  required String from,
  required int nowMs,
}) {
  if (s.ended) return const JamResult.fail(JamError.ended);
  final isHost = from == s.hostDeviceId;
  final items = [...s.items];

  JamResult commit(JamState n) => JamResult.ok(n.copyWith(version: s.version + 1));

  int indexOf(int? id) => id == null ? -1 : items.indexWhere((i) => i.id == id);

  /// State with position frozen at "now" so play/pause keep the clock honest.
  JamState frozen() =>
      s.copyWith(positionMs: s.positionAtTime(nowMs), positionAt: nowMs);

  switch (cmd.type) {
    case JamCommandType.add:
      final item = cmd.item!;
      if (items.length >= maxJamItems) return const JamResult.fail(JamError.full);
      if (item.ownerDeviceId != from) return const JamResult.fail(JamError.forbidden);
      final added = item.copyWith(id: s.nextItemId);
      items.add(added);
      final first = s.currentIndex < 0;
      return commit(s.copyWith(
        items: items,
        nextItemId: s.nextItemId + 1,
        currentIndex: first ? items.length - 1 : s.currentIndex,
        positionMs: first ? 0 : null,
        positionAt: first ? nowMs : null,
      ));

    case JamCommandType.remove:
      final idx = indexOf(cmd.itemId);
      if (idx < 0) return const JamResult.fail(JamError.notFound);
      if (!isHost && items[idx].ownerDeviceId != from) {
        return const JamResult.fail(JamError.forbidden);
      }
      if (!isHost && idx == s.currentIndex) {
        return const JamResult.fail(JamError.forbidden);
      }
      items.removeAt(idx);
      var cur = s.currentIndex;
      var out = s;
      if (idx < cur) {
        cur -= 1;
      } else if (idx == cur) {
        // Removed the current track: the one that slid into its place plays.
        if (cur >= items.length) cur = items.isEmpty ? -1 : items.length - 1;
        out = s.copyWith(positionMs: 0, positionAt: nowMs, playing: items.isEmpty ? false : s.playing);
      }
      return commit(out.copyWith(items: items, currentIndex: cur));

    case JamCommandType.move:
      final idx = indexOf(cmd.itemId);
      if (idx < 0) return const JamResult.fail(JamError.notFound);
      final to = cmd.toIndex!;
      if (to < 0 || to >= items.length) return const JamResult.fail(JamError.invalid);
      if (to == idx) return JamResult.ok(s);
      final curId = s.current?.id;
      final it = items.removeAt(idx);
      items.insert(to, it);
      return commit(s.copyWith(
        items: items,
        currentIndex: curId == null ? -1 : items.indexWhere((i) => i.id == curId),
      ));

    case JamCommandType.play:
      if (s.current == null) return const JamResult.fail(JamError.invalid);
      return commit(frozen().copyWith(playing: true));

    case JamCommandType.pause:
      return commit(frozen().copyWith(playing: false));

    case JamCommandType.seek:
      final p = cmd.positionMs!;
      final dur = s.current?.durationMs ?? 0;
      if (s.current == null || p < 0 || (dur > 0 && p > dur)) {
        return const JamResult.fail(JamError.invalid);
      }
      return commit(s.copyWith(positionMs: p, positionAt: nowMs));

    case JamCommandType.volume:
      final v = cmd.volume!;
      if (v.isNaN || v < 0 || v > 1) return const JamResult.fail(JamError.invalid);
      return commit(s.copyWith(volume: v));

    case JamCommandType.setOutput:
      final d = cmd.deviceId!;
      // Any participant can be the output. Before a roster exists (tests,
      // old peers) only the host and the sender are accepted.
      final known = s.participants.isEmpty
          ? (d == s.hostDeviceId || d == from || isHost)
          : s.participant(d) != null;
      if (!known) return const JamResult.fail(JamError.invalid);
      if (d == s.outputDeviceId) return JamResult.ok(s);
      return commit(frozen().copyWith(outputDeviceId: d));

    case JamCommandType.next:
      if (!isHost) return const JamResult.fail(JamError.forbidden);
      return _advance(s, nowMs, commit);

    case JamCommandType.jump:
      if (!isHost) return const JamResult.fail(JamError.forbidden);
      final idx = indexOf(cmd.itemId);
      if (idx < 0) return const JamResult.fail(JamError.notFound);
      return commit(s.copyWith(
          currentIndex: idx, positionMs: 0, positionAt: nowMs, playing: true));

    case JamCommandType.trackEnded:
      // Natural end of a track, reported by the output device (either role).
      if (s.current?.id != cmd.itemId) return JamResult.ok(s);
      return _advance(s, nowMs, commit);

    case JamCommandType.end:
      if (!isHost) return const JamResult.fail(JamError.forbidden);
      return JamResult.ok(
          s.copyWith(version: s.version + 1, ended: true, playing: false));
  }
}

JamResult _advance(JamState s, int nowMs, JamResult Function(JamState) commit) {
  final n = s.currentIndex + 1;
  if (n >= s.items.length) {
    // Queue finished: stop on the last item, rewound.
    return commit(s.copyWith(playing: false, positionMs: 0, positionAt: nowMs));
  }
  return commit(
      s.copyWith(currentIndex: n, positionMs: 0, positionAt: nowMs));
}
