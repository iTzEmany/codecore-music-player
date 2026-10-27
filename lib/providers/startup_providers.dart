import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_log_providers.dart';
import 'enrich_completer_providers.dart';
import 'library_providers.dart' show scanStateProvider;
import 'online_providers.dart' show autoParts;
import 'settings_providers.dart';
import 'user_activity_provider.dart';

/// Resolves once the app is on screen and has settled (the first frame, then
/// a moment): what is not needed to show it (LAN receiving, the update check)
/// waits for this instead of competing with the first frames.
final startupSettledProvider = FutureProvider<void>((ref) async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  await Future<void>.delayed(const Duration(seconds: 2));
});

/// Starts the background completion once the app is settled and the scan is
/// over, and again each time the scan ends or a switch of the enrichment
/// changes. Watched from the app's root.
final enrichCompleterStartProvider = Provider<void>((ref) {
  final completer = ref.read(enrichCompleterProvider.notifier);
  // Given here and not read by the completer: the activity list watches the
  // completer, and the busy flag and the Registro listen to the activity list.
  completer.activity = ref.watch(userActivityProvider);
  completer.addLog = ref.read(activityLogProvider.notifier).add;
  ref.listen(scanStateProvider.select((s) => s.running), (was, now) {
    if (was == true && !now) unawaited(completer.start());
  });
  ref.listen(
    settingsProvider.select((s) => autoParts(s).map((p) => p.name).join(',')),
    (_, _) => unawaited(completer.start()),
  );
  ref.read(startupSettledProvider.future).then((_) {
    if (ref.mounted && !ref.read(scanStateProvider).running) {
      unawaited(completer.start());
    }
  });
});
