import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../services/jam/jam_host.dart';
import 'jam_screen.dart';

/// Asks whether to start a Jam requested by a nearby device.
class JamRequestDialog extends ConsumerWidget {
  const JamRequestDialog({super.key, required this.request});

  final JamRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ctrl = ref.read(jamProvider.notifier);
    return AlertDialog(
      title: Text(l.jamIncomingTitle(request.fromName)),
      content: Text(l.jamIncomingDialog(request.fromName)),
      actions: [
        TextButton(
          onPressed: () {
            ctrl.decline(request);
            Navigator.of(context).pop();
          },
          child: Text(l.decline),
        ),
        FilledButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            nav.pop();
            await ctrl.acceptRequest(request);
            if (ref.read(jamProvider).active) {
              nav.push(MaterialPageRoute<void>(builder: (_) => const JamScreen()));
            }
          },
          child: Text(l.accept),
        ),
      ],
    );
  }
}
