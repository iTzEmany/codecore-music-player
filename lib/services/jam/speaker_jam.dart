import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;

import '../../core/app_log.dart';
import 'jam_models.dart';

/// Where this device stands in the Jam, as [SpeakerJam] needs to see it.
enum SpeakerRole { none, host, guest, busy }

class SpeakerJamView {
  const SpeakerJamView({
    this.role = SpeakerRole.none,
    this.speaker = false,
    this.awaySince,
    this.guests = 0,
    this.iAmOutput = false,
  });

  final SpeakerRole role;

  /// The Jam is a speaker's Jam.
  final bool speaker;
  final int? awaySince;

  /// Members other than the host.
  final int guests;

  /// This device is the only output (a guest whose speaker plays).
  final bool iAmOutput;
}

/// What [SpeakerJam] asks of the Jam controller.
abstract interface class SpeakerJamPort {
  SpeakerJamView get view;
  Stream<void> get changes;

  /// Opens the Jam without guests (or turns the running one into the speaker's).
  Future<void> open();
  Future<void> closeSilently();
  Future<void> send(JamCommand cmd);
  Future<void> end();
}

/// How long a Jam with guests waits for its speaker before ending (R-114).
const speakerJamGrace = Duration(minutes: 10);

/// Follows the speaker for the Jam: opens it when the speaker connects, pauses it
/// when it goes, ends it after [speakerJamGrace] (R-111…R-115, R-119).
class SpeakerJam {
  SpeakerJam({
    required Stream<bool> speakerConnected,
    required this.connected,
    required this.enabled,
    required this.port,
    Timer Function(Duration, void Function())? timer,
  }) : _timer = timer ?? Timer.new {
    _subs = [speakerConnected.listen((_) => refresh()), port.changes.listen((_) {
      _closing = false;
      refresh();
    })];
    refresh();
  }

  final bool Function() connected, enabled;
  final SpeakerJamPort port;
  final Timer Function(Duration, void Function()) _timer;
  late final List<StreamSubscription<void>> _subs;

  final _offer = ValueNotifier<bool>(false);

  /// A guest's speaker is there while the Jam is stopped: offer to play on it.
  ValueListenable<bool> get offerPending => _offer;

  bool? _prev;
  var _opened = false, _awaySent = false, _backSent = false, _closing = false;
  int? _declinedAway;
  Timer? _grace;

  /// Call when the enabled switch changes.
  void refresh() {
    final v = port.view;
    final conn = connected();
    final changed = conn != _prev;
    _prev = conn;
    if (!conn || !enabled()) _opened = false;
    if (conn) _awaySent = false;
    switch (v.role) {
      case SpeakerRole.host:
        _host(v, conn, changed);
      case SpeakerRole.guest:
        _guest(v, conn, changed);
      case SpeakerRole.none:
        _cancelGrace();
        _openIfPlugged(conn);
      case SpeakerRole.busy:
        _cancelGrace();
    }
    if (v.role != SpeakerRole.guest || !v.speaker) _offer.value = false;
    if (v.awaySince == null) _backSent = false;
  }

  void _host(SpeakerJamView v, bool conn, bool changed) {
    if (!v.speaker) {
      _cancelGrace();
      _openIfPlugged(conn);
      return;
    }
    if (v.awaySince == null) _awaySent = false;
    if (v.awaySince != null) {
      _grace ??= _timer(speakerJamGrace, () {
        _grace = null;
        // Nobody is waiting: no message (R-115).
        _run('grace end', () => port.view.guests == 0 ? port.closeSilently() : port.end());
      });
    } else {
      _cancelGrace();
    }
    if (!conn) {
      if (v.awaySince != null) return;
      if (v.guests == 0) {
        if (!_closing) {
          _closing = true;
          _run('closeSilently', port.closeSilently);
        }
      } else if (v.iAmOutput && !_awaySent) {
        _awaySent = true;
        _run('speakerAway', () => port.send(const JamCommand.speakerAway()),
            () => _awaySent = false);
      }
    } else if (v.awaySince != null) {
      // Ours is there: back to play, even if a guest's speaker was the one that went (D-220).
      if (!_backSent) {
        _backSent = true;
        _run('speakerBack', () => port.send(const JamCommand.speakerBack()),
            () => _backSent = false);
      }
    } else if (!enabled() && v.guests == 0) {
      _opened = false;
      _run('closeSilently', port.closeSilently);
    }
  }

  void _openIfPlugged(bool conn) {
    if (conn && enabled() && !_opened) {
      _opened = true;
      _run('open', port.open, () => _opened = false);
    }
  }

  void _run(String what, Future<void> Function() f, [void Function()? onFail]) {
    unawaited(f().catchError((Object e, StackTrace st) {
      AppLog.w('speaker jam: $what failed', e, st);
      onFail?.call();
    }));
  }

  void _guest(SpeakerJamView v, bool conn, bool changed) {
    if (!v.speaker) return;
    final away = v.awaySince;
    _offer.value = away != null && conn && enabled() && _declinedAway != away;
    if (away == null) {
      _declinedAway = null;
      if (v.iAmOutput && !conn && !_awaySent) {
        _awaySent = true;
        _run('speakerAway', () => port.send(const JamCommand.speakerAway()),
            () => _awaySent = false);
      }
    }
  }

  Future<void> acceptOffer() async {
    _offer.value = false;
    await port.send(const JamCommand.offerSpeaker());
  }

  void declineOffer() {
    _declinedAway = port.view.awaySince;
    _offer.value = false;
  }

  void _cancelGrace() {
    _grace?.cancel();
    _grace = null;
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _cancelGrace();
    _offer.dispose();
  }
}
