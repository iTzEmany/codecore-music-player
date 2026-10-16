import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/player_providers.dart';
import 'providers/settings_providers.dart';
import 'providers/share_hub.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';

class CodecoreApp extends ConsumerWidget {
  const CodecoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(shareAutoStartProvider);
    final s = ref.watch(settingsProvider);
    ref.read(audioHandlerProvider)
      ..setNormalize(s.normalizeVolume)
      ..setSpeed(s.playbackSpeed);
    return MaterialApp(
      title: 'Codecore',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(appThemeIdFromName(s.theme), s.compactMode),
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
      home: const AppShell(),
    );
  }
}
