import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/speaker_providers.dart';
import '../../../services/audio/bluetooth_outputs.dart';
import '../../../services/audio/speaker_monitor.dart';
import '../../widgets/cc_sheet.dart';
import '../../theme/tokens.dart';

final _queue = <(BuildContext, SpeakerPrompt)>[];
var _open = false;
Timer? _retry;

/// Shows [prompt] in a sheet, one at a time: the others wait in a FIFO queue.
/// While a dialog (a Jam request, say) is on top of the shell's route the
/// queue waits too, polled once a second: a route has no "closed" callback
/// for someone else's route, and the poll stops as soon as the queue is empty.
Future<void> showSpeakerPrompt(BuildContext context, SpeakerPrompt prompt) async {
  _queue.add((context, prompt));
  _next();
}

void _next() {
  _retry?.cancel();
  if (_open || _queue.isEmpty) return;
  final (context, prompt) = _queue.first;
  if (!context.mounted) {
    _queue.removeAt(0);
    return _next();
  }
  if (ModalRoute.of(context)?.isCurrent == false) {
    _retry = Timer(const Duration(seconds: 1), _next);
    return;
  }
  _queue.removeAt(0);
  _open = true;
  final monitor = ProviderScope.containerOf(context).read(speakerMonitorProvider);
  showCcSheet<void>(
    context: context,
    builder: (_) => switch (prompt) {
      PermissionPrompt() => const SpeakerPermissionSheet(),
      AskPrompt(:final output) => SpeakerAskSheet(output: output),
    },
  ).whenComplete(() {
    _open = false;
    // Swiped away without an answer: ask again at the next opening.
    if (prompt case AskPrompt(:final output)) monitor.dismissed(output.address);
    _next();
  });
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
