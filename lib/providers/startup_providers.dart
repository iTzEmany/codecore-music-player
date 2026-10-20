import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves once the app is on screen and has settled (the first frame, then
/// a moment): what is not needed to show it (LAN receiving, the update check)
/// waits for this instead of competing with the first frames.
final startupSettledProvider = FutureProvider<void>((ref) async {
  await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
  await Future<void>.delayed(const Duration(seconds: 2));
});
