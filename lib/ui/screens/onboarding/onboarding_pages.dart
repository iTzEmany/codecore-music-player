import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/exportify_providers.dart';
import '../../../providers/folder_actions.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../theme/tokens.dart';
import '../import/exportify_remind_choice.dart';

class _Page extends StatelessWidget {
  const _Page({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cc = context.cc;
    final theme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: CcDims.margin + CcDims.gap8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cc.accent,
              borderRadius: BorderRadius.circular(CcDims.rSheet),
            ),
            child: Icon(icon, size: 40, color: cc.onAccent),
          ),
          const SizedBox(height: 24),
          Text(title, style: theme.headlineSmall),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

Widget _body(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(bottom: CcDims.gap12),
  child: Text(
    text,
    style: Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: context.cc.textMuted),
  ),
);

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Page(
      icon: Icons.music_note_rounded,
      title: l.onboardingWelcomeTitle,
      children: [_body(context, l.onboardingWelcomeBody)],
    );
  }
}

/// Folders are added (and scanned) here.
class FoldersPage extends ConsumerStatefulWidget {
  const FoldersPage({super.key, required this.askAudioPermission});

  final bool askAudioPermission;

  @override
  ConsumerState<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends ConsumerState<FoldersPage> {
  bool? _granted;

  Future<void> _allow() async {
    final ok = await ensureAudioPermission();
    if (mounted) setState(() => _granted = ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final folders = ref.watch(foldersProvider).value ?? const [];
    return _Page(
      icon: Icons.folder_rounded,
      title: l.onboardingFoldersTitle,
      children: [
        _body(context, l.onboardingFoldersBody),
        if (widget.askAudioPermission) ...[
          // Said before Android asks, so the system prompt is not a surprise.
          _body(context, l.permissionExplain),
          Align(
            alignment: Alignment.centerLeft,
            child: _granted == true
                ? Chip(
                    avatar: Icon(
                      Icons.check_circle_rounded,
                      color: context.cc.accent,
                    ),
                    label: Text(l.onboardingAccessGranted),
                  )
                : OutlinedButton.icon(
                    onPressed: _allow,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(l.onboardingAllowAccess),
                  ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: () => addFolderAndScan(ref),
          icon: const Icon(Icons.create_new_folder_rounded),
          label: Text(l.addFolder),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => addDefaultFolderAndScan(ref), child: Text(l.useDefaultFolder)),
        if (folders.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l.onboardingFoldersAdded(folders.length),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (final f in folders)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined),
              title: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ],
    );
  }
}

/// The two online features, off until the user turns them on.
class OnlinePage extends ConsumerWidget {
  const OnlinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return _Page(
      icon: Icons.cloud_outlined,
      title: l.onboardingOnlineTitle,
      children: [
        _body(context, l.onboardingOnlineBody),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.autoEnrich),
          subtitle: Text(l.autoEnrichHint),
          value: s.autoEnrich,
          onChanged: (v) => notifier.update((c) => c.copyWith(autoEnrich: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.autoLyrics),
          subtitle: Text(l.autoLyricsHint),
          value: s.autoLyrics,
          onChanged: (v) => notifier.update((c) => c.copyWith(autoLyrics: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.deezerMeta),
          subtitle: Text(l.deezerMetaHint),
          value: s.deezerMeta,
          onChanged: (v) => notifier.update((c) => c.copyWith(deezerMeta: v)),
        ),
      ],
    );
  }
}

/// Optional: how to bring Spotify playlists in, and the reminder (off).
class SpotifyPage extends ConsumerWidget {
  const SpotifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lines = l.onboardingSpotifyBody.split('\n');
    return _Page(
      icon: Icons.playlist_add_rounded,
      title: l.onboardingSpotifyTitle,
      children: [
        for (final line in lines) _body(context, line),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => openExportify(ref),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l.csvImportOpenExportify),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.exportifyRemindTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        const ExportifyRemindChoice(),
      ],
    );
  }
}

class SharePage extends StatelessWidget {
  const SharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cc = context.cc;
    return _Page(
      icon: Icons.devices_rounded,
      title: l.onboardingShareTitle,
      children: [
        _body(context, l.onboardingYoutubeBody),
        Container(
          padding: const EdgeInsets.all(CcDims.gap12),
          margin: const EdgeInsets.only(bottom: CcDims.gap12),
          decoration: BoxDecoration(
            color: cc.surface1,
            borderRadius: BorderRadius.circular(CcDims.rCard),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: cc.accentSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.ytLegal,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        _body(context, l.onboardingJamBody),
        _body(context, l.onboardingSendBody),
      ],
    );
  }
}
