import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform.dart';
import '../services/audio/speaker_monitor.dart';

/// The monitor; started once the shell asks for it. Inert off Android.
final speakerMonitorProvider = Provider<SpeakerMonitor>((ref) {
  final m = SpeakerMonitor();
  ref.onDispose(m.dispose);
  if (isAndroid) {
    unawaited(m.start());
    // Every opening reads the connected outputs again (K-JC-03).
    final life = AppLifecycleListener(onResume: () => unawaited(m.refresh()));
    ref.onDispose(life.dispose);
  }
  return m;
});

/// Ticks whenever what the settings show may have changed.
final speakerChangesProvider = StreamProvider<void>(
  (ref) => ref.watch(speakerMonitorProvider).changes,
);

/// A speaker is connected now (answer «yes», or guessed from its class).
final speakerConnectedProvider = StreamProvider<bool>(
  (ref) => ref.watch(speakerMonitorProvider).speakerConnected,
);

/// The permission sheet and «È una cassa?», one at a time (the shell opens them).
final speakerPromptsProvider = StreamProvider<SpeakerPrompt>(
  (ref) => ref.watch(speakerMonitorProvider).prompts,
);
