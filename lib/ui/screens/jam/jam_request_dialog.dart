import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/jam_providers.dart';
import '../../../services/jam/jam_host.dart';
import 'jam_screen.dart';

/// Asks whether to start a Jam requested by a nearby device.
class JamRequestDialog extends ConsumerStatefulWidget {
  const JamRequestDialog({super.key, required this.request});

  final JamRequest request;

  @override
  ConsumerState<JamRequestDialog> createState() => _JamRequestDialogState();
}

class _JamRequestDialogState extends ConsumerState<JamRequestDialog> {
  Timer? _watch;

  JamRequest get request => widget.request;

  @override
  void initState() {
    super.initState();
    // The requester may cancel (or the request expire) while the dialog is up.
    _watch = Timer.periodic(const Duration(seconds: 1), (_) {
      if (request.status != JamRequestStatus.pending && mounted) {
        _watch?.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // The dialog is gone after pop(): keep what is needed beforehand.
            final nav = Navigator.of(context);
            final container = ProviderScope.containerOf(context);
            nav.pop();
            await ctrl.acceptRequest(request);
            if (container.read(jamProvider).active && nav.mounted) {
              nav.push(MaterialPageRoute<void>(builder: (_) => const JamScreen()));
            }
          },
          child: Text(l.accept),
        ),
      ],
    );
  }
}
