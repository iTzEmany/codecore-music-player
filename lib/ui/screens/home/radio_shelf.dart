import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/radio_repository.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/radio_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/motion.dart';
import '../../widgets/radio_art.dart';
import '../../widgets/section_header.dart';
import '../radio/radio_actions.dart';

/// «Le tue radio»: the saved stations as round pictures; a tap listens, with
/// the shelf as the queue. Nothing at all while none is saved.
class HomeRadioShelf extends ConsumerWidget {
  const HomeRadioShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final saved = ref.watch(savedRadiosProvider).value ?? const <SavedRadio>[];
    if (saved.isEmpty) return const SizedBox.shrink();
    final stations = [for (final r in saved) r.toStation()];
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l.homeYourRadios),
        SizedBox(
          height: 112 + 20 * MediaQuery.textScalerOf(context).scale(1),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: CcDims.margin - 6),
            itemCount: stations.length,
            itemBuilder: (_, i) => PressScale(
              child: InkWell(
                key: ValueKey('home-radio-${stations[i].id}'),
                borderRadius: BorderRadius.circular(CcDims.rGrid),
                onTap: () => playRadioList(context, ref, stations, i, l.homeYourRadios),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 84,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RadioArt(station: stations[i], size: 72, circle: true),
                        const SizedBox(height: 6),
                        Text(
                          stations[i].name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
