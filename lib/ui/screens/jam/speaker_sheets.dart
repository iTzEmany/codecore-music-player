import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_log.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../providers/speaker_providers.dart';
import '../../../services/audio/bluetooth_outputs.dart';
import '../../../services/audio/speaker_monitor.dart';
import '../../../services/jam/speaker_jam.dart';
import '../../widgets/cc_sheet.dart';
import '../../theme/tokens.dart';

class _Item {
  _Item(this.context, this.builder, this.onClosed, {this.valid, this.offer = false});
  final BuildContext context;
  final WidgetBuilder builder;
  final void Function() onClosed;

  /// Checked just before opening: a stale item is dropped.
  final bool Function()? valid;
  final bool offer;
}

final _queue = <_Item>[];
var _open = false;
Timer? _retry;
Route<void>? _offerRoute;

/// Shows [prompt] in a sheet, one at a time: the others wait in a FIFO queue.
/// While a dialog (a Jam request, say) is on top of the shell's route the
/// queue waits too, polled once a second: a route has no "closed" callback
/// for someone else's route, and the poll stops as soon as the queue is empty.
Future<void> showSpeakerPrompt(BuildContext context, SpeakerPrompt prompt) async {
  final monitor = ProviderScope.containerOf(context).read(speakerMonitorProvider);
  _queue.add(
    _Item(
      context,
      (_) => switch (prompt) {
        PermissionPrompt() => const SpeakerPermissionSheet(),
        AskPrompt(:final output) => SpeakerAskSheet(output: output),
      },
      // Swiped away without an answer: ask again at the next opening.
      () {
        if (prompt case AskPrompt(:final output)) monitor.dismissed(output.address);
      },
    ),
  );
  _next();
}

/// Guest side (R-119): «Suonare la Jam sulla tua cassa?», queued like the others
/// and never twice. Swiping it away counts as «No»; [closeSpeakerOffer] does not.
void showSpeakerOffer(BuildContext context, SpeakerJam jam) {
  if (_offerRoute != null || _queue.any((i) => i.offer)) return;
  var answered = false, closedByUs = false;
  _queue.add(
    _Item(
      context,
      (ctx) {
        _offerRoute = ModalRoute.of(ctx) as Route<void>?;
        return _OfferSheet(
          jam: jam,
          onAnswer: () => answered = true,
        );
      },
      () {
        closedByUs = _offerRoute == null;
        _offerRoute = null;
        if (!answered && !closedByUs) jam.declineOffer();
      },
      valid: () => jam.offerPending.value,
      offer: true,
    ),
  );
  _next();
}

/// The offer is gone (the speaker dropped, the Jam moved on): no sheet, no answer.
void closeSpeakerOffer() {
  _queue.removeWhere((i) => i.offer);
  final r = _offerRoute;
  if (r == null) return;
  _offerRoute = null;
  r.navigator?.removeRoute(r);
}

void _next() {
  _retry?.cancel();
  if (_open || _queue.isEmpty) return;
  final item = _queue.first;
  final context = item.context;
  if (!context.mounted || item.valid?.call() == false) {
    _queue.removeAt(0);
    return _next();
  }
  if (ModalRoute.of(context)?.isCurrent == false) {
    _retry = Timer(const Duration(seconds: 1), _next);
    return;
  }
  _queue.removeAt(0);
  _open = true;
  showCcSheet<void>(context: context, builder: item.builder).whenComplete(() {
    _open = false;
    item.onClosed();
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

class _OfferSheet extends StatelessWidget {
  const _OfferSheet({required this.jam, required this.onAnswer});

  final SpeakerJam jam;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = Navigator.of(context);
    void reply(bool yes) {
      onAnswer();
      nav.pop();
      if (yes) {
        unawaited(jam.acceptOffer().catchError((Object e, StackTrace st) {
          AppLog.w('speaker jam: offer failed', e, st);
        }));
      } else {
        jam.declineOffer();
      }
    }

    return _SheetBody(
      title: l.speakerOfferTitle,
      body: l.speakerOfferBody,
      actions: [
        TextButton(onPressed: () => reply(false), child: Text(l.speakerNo)),
        FilledButton(onPressed: () => reply(true), child: Text(l.speakerYes)),
      ],
    );
  }
}
