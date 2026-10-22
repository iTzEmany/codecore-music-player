import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/player_providers.dart';
import '../../../providers/radio_providers.dart';
import '../../../services/radio/radio_station.dart';
import '../../../services/radio/stream_link.dart';
import 'radio_labels.dart';

const kRadioTestId = 'manual:test';

/// «Aggiungi indirizzo»: a name and the address of a stream (or of a `.pls` /
/// `.m3u` file). «Prova 10 secondi» plays it so the user can hear it before
/// saving; nothing is sent to Radio Browser.
class AddStationDialog extends ConsumerStatefulWidget {
  const AddStationDialog({super.key, this.testSeconds = 10});

  /// How long the test plays.
  final int testSeconds;

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const AddStationDialog());

  @override
  ConsumerState<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends ConsumerState<AddStationDialog> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  StreamLinkError? _error;
  bool _busy = false, _testing = false;
  Timer? _stopTimer;

  @override
  void dispose() {
    _stopTimer?.cancel();
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  /// The stream address, or null with [_error] set.
  Future<String?> _resolve() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      return await resolveStreamLink(_url.text, ref.read(playlistFetchProvider));
    } on StreamLinkException catch (e) {
      if (mounted) setState(() => _error = e.reason);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _nameFor(String address) {
    final n = _name.text.trim();
    return n.isNotEmpty ? n : (Uri.tryParse(address)?.host ?? address);
  }

  Future<void> _test() async {
    final address = await _resolve();
    if (address == null || !mounted) return;
    final ctrl = ref.read(playerControllerProvider);
    await ctrl.playStations(
      [RadioStation(id: kRadioTestId, name: _nameFor(address), streamUrl: address)],
      0,
    );
    if (!mounted) return;
    setState(() => _testing = true);
    _stopTimer?.cancel();
    _stopTimer = Timer(Duration(seconds: widget.testSeconds), () {
      _stopTest();
      if (mounted) setState(() => _testing = false);
    });
  }

  void _stopTest() {
    _stopTimer?.cancel();
    final handler = ref.read(audioHandlerProvider);
    if (handler.isRadio && handler.currentTrack != null) {
      final entry = ref.read(onlineEntriesProvider)?.radioOf(handler.currentTrack!.id);
      if (entry?.station.id == kRadioTestId) unawaited(ref.read(playerControllerProvider).pause());
    }
  }

  Future<void> _save() async {
    final address = await _resolve();
    if (address == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.l10n.radioSavedDone;
    _stopTest();
    await ref.read(radioRepositoryProvider).saveManual(_name.text, address);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(saved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.radioAddAddress),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('radio-add-name'),
              controller: _name,
              decoration: InputDecoration(labelText: l.radioAddName),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('radio-add-url'),
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l.radioAddUrl,
                hintText: 'https://',
                errorText: _error == null ? null : streamLinkErrorText(l, _error!),
                errorMaxLines: 3,
                helperText: _testing ? l.radioAddTesting : null,
                helperMaxLines: 2,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('radio-add-test'),
          onPressed: _busy ? null : _test,
          child: Text(l.radioAddTest),
        ),
        TextButton(
          onPressed: () {
            _stopTest();
            Navigator.of(context).pop();
          },
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const ValueKey('radio-add-save'),
          onPressed: _busy ? null : _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}
