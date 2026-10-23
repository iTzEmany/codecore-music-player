import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/share_hub.dart';
import '../../../services/share/discovery.dart';
import '../../../services/share/pairing.dart';
import '../../../services/share/pairing_client.dart';
import '../../../services/share/trusted_devices.dart';
import '../../theme/tokens.dart';

/// The PIN typed on the device that asked to pair (the one that does not show
/// it). Returns the digits, or null to give up.
Future<String?> askPairingPin(
  BuildContext context,
  String peerName,
  String peerFingerprint,
  int? attemptsLeft,
) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinDialog(
      name: peerName,
      fingerprint: peerFingerprint,
      attemptsLeft: attemptsLeft,
    ),
  );
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.name,
    required this.fingerprint,
    this.attemptsLeft,
  });

  final String name, fingerprint;
  final int? attemptsLeft;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.pairPinTitle(widget.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.pairPinHint(widget.name)),
          if (widget.attemptsLeft != null) ...[
            const SizedBox(height: 8),
            Text(
              l.pairPinWrong(widget.attemptsLeft!),
              style: TextStyle(color: context.cc.error),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _pin,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.headlineSmall,
            onChanged: (_) => setState(() {}),
          ),
          Text(
            l.pairFingerprint(formatFingerprint(widget.fingerprint)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(l.pairCompare, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _pin.text.length == 6
              ? () => Navigator.pop(context, _pin.text)
              : null,
          child: Text(l.pairConfirm),
        ),
      ],
    );
  }
}

/// Shown on the device that is asked to pair: the PIN to copy over to the
/// other one and its fingerprint. «Conferma» works once the PIN was proven.
class PairRequestDialog extends ConsumerStatefulWidget {
  const PairRequestDialog({super.key, required this.request});

  final PairRequest request;

  @override
  ConsumerState<PairRequestDialog> createState() => _PairRequestDialogState();
}

class _PairRequestDialogState extends ConsumerState<PairRequestDialog> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // The request changes state on its own (PIN proven, expired): look again.
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final st = widget.request.state;
      if (st == PairState.expired ||
          st == PairState.blocked ||
          st == PairState.rejected ||
          st == PairState.accepted) {
        Navigator.of(context).maybePop();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hub = ref.read(shareHubProvider.notifier);
    final r = widget.request;
    return AlertDialog(
      title: Text(l.pairRequestTitle(r.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.pairRequestBody),
          const SizedBox(height: 12),
          Center(
            child: Text(
              r.pin,
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(letterSpacing: 6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.pairFingerprint(formatFingerprint(r.fingerprint)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(l.pairCompare, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            hub.rejectPairing(r);
            Navigator.pop(context);
          },
          child: Text(l.decline),
        ),
        FilledButton(
          onPressed: r.state == PairState.pinOk
              ? () {
                  hub.acceptPairing(r);
                  Navigator.pop(context);
                }
              : null,
          child: Text(l.pairConfirm),
        ),
      ],
    );
  }
}

/// Pairs with [peer], asking for the PIN; reports the outcome in a snackbar.
Future<void> pairFlow(BuildContext context, WidgetRef ref, Peer peer) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  String msg;
  try {
    final paired = await ref
        .read(shareHubProvider.notifier)
        .pairWith(
          peer,
          (fp, left) => askPairingPin(context, peer.name, fp, left),
        );
    msg = l.pairDone(paired.name);
  } on PairingException catch (e) {
    if (e.error == PairingError.cancelled) return;
    msg = switch (e.error) {
      PairingError.blocked => l.pairBlocked,
      PairingError.rejected => l.pairRejected,
      PairingError.expired => l.pairExpired,
      PairingError.unreachable => l.shareErrUnreachable,
      _ => l.pairFailed,
    };
  }
  messenger.showSnackBar(SnackBar(content: Text(msg)));
}
