import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/home_sections.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/library_providers.dart';
import '../../shell/shell_nav.dart';
import '../../theme/tokens.dart';
import '../../widgets/activity_button.dart';
import '../../widgets/empty_state.dart';
import '../library/folders_sheet.dart';
import '../settings/settings_screen.dart';
import 'exportify_card.dart';
import 'home_blocks.dart';
import 'home_bottom_rows.dart';
import 'resume_rows.dart';

/// The clock of the greeting; tests override it to be independent of the time of day.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

String _greeting(AppLocalizations l, int hour) =>
    switch (greetingForHour(hour)) {
      Greeting.morning => l.greetingMorning,
      Greeting.afternoon => l.greetingAfternoon,
      Greeting.evening => l.greetingEvening,
    };

/// Home: shuffle everything, shortcuts, what to resume, the latest additions
/// as a fan and a few short lists. Sections without data stay hidden.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context).textTheme;
    final trackCount = ref.watch(
      tracksProvider(false).select((t) => t.value?.length ?? 0),
    );
    final folders = ref.watch(foldersProvider).value;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(CcDims.margin, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _greeting(l, ref.read(clockProvider)().hour),
              style: theme.headlineSmall,
            ),
          ),
          const ActivityButton(),
          IconButton(
            tooltip: l.navSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => ShellNav.open<void>(
              context,
              Scaffold(
                appBar: AppBar(title: Text(l.navSettings)),
                body: const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
    );

    if (trackCount == 0 && folders != null && folders.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: EmptyState(
                  icon: Icons.library_music,
                  message: l.addMusicFolder,
                  actionLabel: l.addFolder,
                  onAction: () => addFolderAndScan(ref),
                  secondaryLabel: l.useDefaultFolder,
                  onSecondary: () => addDefaultFolderAndScan(ref),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              children: [
                header,
                const ExportifyCard(),
                const ShuffleHero(),
                const ShortcutsRow(),
                const ResumeList(),
                const AddedLately(),
                const HomeBottomRows(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
