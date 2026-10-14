import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_providers.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';

class CodecoreApp extends ConsumerWidget {
  const CodecoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'Codecore',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(appThemeIdFromName(s.theme), s.fontScale, s.compactMode),
      home: const AppShell(),
    );
  }
}
