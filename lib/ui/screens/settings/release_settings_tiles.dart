import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/releases_providers.dart';

/// Settings → «Nuove uscite»: the most listened artists, the notification (a
/// tile only on Android) and the Wi‑Fi only rule.
class ReleaseSettingsTiles extends ConsumerWidget {
  const ReleaseSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final o = ref.watch(releaseOptionsProvider);
    final n = ref.read(releaseOptionsProvider.notifier);
    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('releases-top-artists'),
          title: Text(l.releasesTopArtists),
          subtitle: Text(l.releasesTopArtistsHint),
          value: o.topArtists,
          onChanged: n.setTopArtists,
        ),
        if (isAndroid)
          SwitchListTile(
            key: const ValueKey('releases-notify'),
            title: Text(l.releasesNotify),
            subtitle: Text(l.releasesNotifyHint),
            value: o.notify,
            onChanged: n.setNotify,
          ),
        SwitchListTile(
          key: const ValueKey('releases-unmetered'),
          title: Text(l.releasesUnmetered),
          subtitle: Text(l.releasesUnmeteredHint),
          value: o.unmeteredOnly,
          onChanged: n.setUnmeteredOnly,
        ),
      ],
    );
  }
}
