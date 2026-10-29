import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings/jam_secret_store.dart';
import '../services/jam/jam_gate.dart';

final jamSecretStoreProvider = Provider<JamSecretStore>((_) => PrefsJamSecretStore());

/// Suspended and blocked senders of Jam requests (the UI reads and edits it; it is a Listenable).
final jamGateProvider = Provider<JamGate>((ref) {
  final gate = JamGate(ref.watch(jamSecretStoreProvider));
  ref.onDispose(gate.dispose);
  return gate;
});
