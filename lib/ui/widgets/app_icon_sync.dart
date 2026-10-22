import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_log.dart';
import '../../data/settings/settings_store.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_icon_providers.dart';
import '../../providers/settings_providers.dart';

/// Keeps the launcher icon in step with the theme (Android): when the look
/// changes to one with another icon, asks once, or follows the saved answer.
class AppIconSync extends ConsumerWidget {
  const AppIconSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appIconSupportedProvider)) {
      ref.listen(appIconVariantProvider, (_, variant) => _onVariant(context, ref, variant));
    }
    return child;
  }

  Future<void> _onVariant(BuildContext context, WidgetRef ref, String variant) async {
    try {
      await _sync(context, ref, variant);
    } catch (e, st) {
      AppLog.w('launcher icon sync failed', e, st);
    }
  }

  Future<void> _sync(BuildContext context, WidgetRef ref, String variant) async {
    final follow = ref.read(settingsProvider).iconFollow;
    if (follow == IconFollow.off) return;
    final channel = ref.read(appIconChannelProvider);
    if (follow == IconFollow.on) return channel.setIcon(variant);
    final current = await channel.current();
    // Back to the icon in use: clears any switch asked for earlier.
    if (current == variant) return channel.setIcon(variant);
    if (!context.mounted) return;
    final answer = await showDialog<({bool change, bool remember})>(
      context: context,
      builder: (_) => const _AskDialog(),
    );
    if (answer == null) return;
    if (answer.remember) {
      ref.read(settingsProvider.notifier).update(
            (s) => s.copyWith(iconFollow: answer.change ? IconFollow.on : IconFollow.off),
          );
    }
    if (answer.change) {
      await channel.setIcon(variant);
    } else if (current != null) {
      await channel.setIcon(current);
    }
  }
}

class _AskDialog extends StatefulWidget {
  const _AskDialog();

  @override
  State<_AskDialog> createState() => _AskDialogState();
}

class _AskDialogState extends State<_AskDialog> {
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.iconAskTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.iconProblems),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l.iconDontAsk),
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, (change: false, remember: _remember)),
          child: Text(l.iconKeep),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (change: true, remember: _remember)),
          child: Text(l.iconChange),
        ),
      ],
    );
  }
}
