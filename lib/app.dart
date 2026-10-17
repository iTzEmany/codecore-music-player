import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/equalizer_providers.dart';
import 'providers/player_providers.dart';
import 'providers/settings_providers.dart';
import 'providers/share_hub.dart';
import 'providers/update_providers.dart';
import 'l10n/l10n_ext.dart';
import 'ui/screens/onboarding/onboarding_gate.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class CodecoreApp extends ConsumerWidget {
  const CodecoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(shareAutoStartProvider);
    ref.watch(equalizerApplierProvider);
    ref.watch(outputRouteSyncProvider);
    // A new version, at most once a day and only if the user asked for it.
    ref.listen(updateOnStartProvider, (_, next) {
      final info = next.value;
      if (info == null) return;
      _messengerKey.currentState?.showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Builder(builder: (c) => Text(c.l10n.updateAvailable(info.version))),
      ));
    });
    final s = ref.watch(settingsProvider);
    ref.read(audioHandlerProvider)
      ..recordHistory = s.recordHistory
      ..setNormalize(s.normalizeVolume)
      ..setSpeed(s.playbackSpeed)
      ..setTransition(
        s.transition,
        plainInAlbum: s.crossfadePlainInAlbum,
        crossfadeSeconds: s.crossfadeSeconds,
      );
    return MaterialApp(
      title: 'Codecore',
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(
        appThemeIdFromName(s.theme),
        s.compactMode,
        accent: accentFromName(s.accent),
      ),
      locale: Locale(s.language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: s.reducedMotion,
          textScaler: TextScaler.linear(s.fontScale),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const OnboardingGate(child: AppShell()),
    );
  }
}
