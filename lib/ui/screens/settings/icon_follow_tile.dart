import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings/settings_store.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/app_icon_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/app_icon/app_icon.dart';

/// Settings switch for the launcher icon following the theme (Android only).
class IconFollowTile extends ConsumerWidget {
  const IconFollowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appIconSupportedProvider)) return const SizedBox.shrink();
    final l = context.l10n;
    final on = ref.watch(settingsProvider.select((s) => s.iconFollow == IconFollow.on));
    return SwitchListTile(
      title: Text(l.iconFollowTitle),
      subtitle: Text(l.iconFollowSubtitle),
      secondary: IconButton(
        tooltip: l.iconAskTitle,
        icon: const Icon(Icons.info_outline),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            content: SingleChildScrollView(child: Text(l.iconProblems)),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l.close))],
          ),
        ),
      ),
      value: on,
      onChanged: (v) {
        ref.read(settingsProvider.notifier).update(
              (s) => s.copyWith(iconFollow: v ? IconFollow.on : IconFollow.off),
            );
        ref
            .read(appIconChannelProvider)
            .setIcon(v ? ref.read(appIconVariantProvider) : defaultAppIcon);
      },
    );
  }
}
