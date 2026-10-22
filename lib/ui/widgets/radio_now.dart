import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/player_providers.dart';
import '../../providers/radio_providers.dart';
import '../../services/audio/online_entries.dart';
import '../../services/radio/radio_station.dart';
import '../screens/radio/radio_actions.dart';
import '../screens/radio/radio_labels.dart';
import '../screens/radio/radio_station_sheet.dart';
import '../theme/tokens.dart';

/// The station behind [track], or null when it is not a radio entry.
/// Watches the registry, so a screen rebuilds if the entry changes.
RadioStation? radioOfTrack(WidgetRef ref, Track track) =>
    isOnlineId(track.id) ? ref.watch(onlineEntriesProvider)?.radioOf(track.id)?.station : null;

/// Same, for code that only reads (menus).
RadioStation? radioOfTrackRead(WidgetRef ref, Track track) =>
    isOnlineId(track.id) ? ref.read(onlineEntriesProvider)?.radioOf(track.id)?.station : null;

/// What the screens write for a station: the title on air (or the name) and
/// the line below it (the name when something is on air, else «In diretta»).
({String title, String subtitle}) radioTexts(AppLocalizations l, RadioStation s, String? onAir) =>
    onAir == null ? (title: s.name, subtitle: l.radioLive) : (title: onAir, subtitle: s.name);

/// «● In diretta · MP3 · 128 kbps»: in place of the seek bar.
class NpLiveRow extends StatelessWidget {
  const NpLiveRow({super.key, required this.station});

  final RadioStation station;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    final quality = radioQualityLine(station);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 10, color: cc.accent),
          const SizedBox(width: 8),
          Text(l.radioLive, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cc.text)),
          if (quality.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(quality, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cc.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// Star that saves or takes out the station, for the players.
class RadioStarButton extends ConsumerWidget {
  const RadioStarButton({super.key, required this.station, this.compact = false, this.color});

  final RadioStation station;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cc = context.cc;
    final saved = ref.watch(savedRadioIdsProvider.select((s) => s.contains(station.id)));
    return IconButton(
      tooltip: saved ? l.radioUnsave : l.radioSave,
      visualDensity: compact ? VisualDensity.compact : null,
      onPressed: () => toggleSavedRadio(context, ref, station),
      icon: Icon(
        saved ? Icons.star_rounded : Icons.star_border_rounded,
        color: saved ? cc.accent : (color ?? cc.text),
      ),
    );
  }
}

/// Under the title of a radio: look the song on air up, or open the website.
class NpRadioActions extends ConsumerWidget {
  const NpRadioActions({super.key, required this.station, required this.onAir});

  final RadioStation station;
  final String? onAir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Wrap(
      children: [
        if (onAir != null && kEnableYoutube)
          TextButton.icon(
            key: const ValueKey('radio-search-song'),
            onPressed: () => searchOnAir(context, ref, onAir!),
            icon: const Icon(Icons.search_rounded, size: 20),
            label: Text(l.radioSearchSong),
          ),
        if (station.homepage.isNotEmpty)
          TextButton.icon(
            onPressed: () => openStationSite(context, station.homepage),
            icon: const Icon(Icons.public_rounded, size: 20),
            label: Text(l.radioSite),
          ),
      ],
    );
  }
}
