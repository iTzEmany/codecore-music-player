import 'jam_clock.dart';
import 'jam_host.dart' show JamRequest;
import 'jam_models.dart';

/// What [JamController] uses of the guest side of a Jam, whatever the
/// transport (LAN HTTP today, a remote bridge later). Establishing the link
/// (join) is transport specific and stays on the concrete class.
abstract class JamGuestLink {
  JamState? get state;
  Stream<JamState> get states;
  Stream<void> get lost;

  /// Null for a guest that has no LAN address of the host (remote guest).
  String? get sessionId;
  String? get hostBase;
  String? get fileToken;

  Future<JamResult> send(JamCommand cmd);
  Future<JamTimeSample?> probeHostTime(int Function() localNow);
  Future<bool> invite(JamRequest request);
  Future<void> leave();
  void cancelJoin();
  Future<void> dispose();
}
