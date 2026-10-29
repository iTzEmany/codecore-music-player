import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/speaker_providers.dart';
import '../../../services/audio/bluetooth_outputs.dart';
import '../../../services/audio/speaker_monitor.dart';
import '../../widgets/cc_sheet.dart';
import '../../theme/tokens.dart';

bool _open = false;

/// Opens the sheet for [prompt], never on top of another speaker sheet.
Future<void> showSpeakerPrompt(BuildContext context, SpeakerPrompt prompt) async {
  if (_open) return;
  _open = true;
  try {
    await showCcSheet<void>(
      context: context,
      builder: (_) => switch (prompt) {
        PermissionPrompt() => const SpeakerPermissionSheet(),
        AskPrompt(:final output) => SpeakerAskSheet(output: output),
      },
    );
  } finally {
    _open = false;
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.body, required this.actions});

  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(CcDims.margin, 0, CcDims.margin, CcDims.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(title, style: theme.titleMedium)),
            const SizedBox(height: 8),
            Text(body, style: theme.bodyMedium),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, spacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

/// First Bluetooth output seen: why the permission is needed.
class SpeakerPermissionSheet extends ConsumerWidget {
  const SpeakerPermissionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final monitor = ref.read(speakerMonitorProvider);
    final nav = Navigator.of(context);
    return _SheetBody(
      title: l.speakerPermTitle,
      body: l.speakerPermBody,
      actions: [
        TextButton(
          onPressed: () {
            nav.pop();
            monitor.declinePermission();
          },
          child: Text(l.speakerNotNow),
        ),
        FilledButton(
          onPressed: () {
            nav.pop();
            monitor.askPermission();
          },
          child: Text(l.speakerPermAllow),
        ),
      ],
    );
  }
}

/// «È una cassa?» for a device without an answer.
class SpeakerAskSheet extends ConsumerWidget {
  const SpeakerAskSheet({super.key, required this.output});

  final BluetoothOutput output;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final monitor = ref.read(speakerMonitorProvider);
    final nav = Navigator.of(context);
    void reply(bool yes) {
      nav.pop();
      monitor.answer(output.address, yes, name: output.name);
    }

    return _SheetBody(
      title: l.speakerAskTitle(output.name),
      body: l.speakerAskBody,
      actions: [
        TextButton(onPressed: () => reply(false), child: Text(l.speakerNo)),
        FilledButton(onPressed: () => reply(true), child: Text(l.speakerYes)),
      ],
    );
  }
}
