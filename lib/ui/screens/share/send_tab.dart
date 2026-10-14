import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/share_providers.dart';
import '../../../services/share/lan_server.dart';
import 'track_picker_screen.dart';

class SendTab extends ConsumerStatefulWidget {
  const SendTab({super.key, this.initialTrackIds});

  final List<int>? initialTrackIds;

  @override
  ConsumerState<SendTab> createState() => _SendTabState();
}

class _SendTabState extends ConsumerState<SendTab> {
  late Set<int>? _ids =
      widget.initialTrackIds == null ? null : {...widget.initialTrackIds!};
  ShareInfo? _info;
  bool _starting = false;
  bool _noNetwork = false;
  late final ShareController _controller;

  @override
  void initState() {
    super.initState();
    // Captured now: `ref` must not be used from dispose().
    _controller = ref.read(shareControllerProvider);
  }

  @override
  void dispose() {
    // The server only lives while this screen is open.
    _controller.stopSharing();
    super.dispose();
  }

  Future<void> _pick() async {
    final res = await Navigator.of(context).push<Set<int>>(MaterialPageRoute(
        builder: (_) => TrackPickerScreen(initial: _ids ?? const {})));
    if (res != null && mounted) setState(() => _ids = res);
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _noNetwork = false;
    });
    final info = await _controller.startSharing(_ids?.toList());
    if (!mounted) return;
    setState(() {
      _starting = false;
      _info = info;
      _noNetwork = info == null;
    });
  }

  Future<void> _stop() async {
    await _controller.stopSharing();
    if (mounted) setState(() => _info = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final info = _info;
    if (info != null) return _Active(info: info, onStop: _stop);
    final all = _ids == null;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(l.shareHint),
      const SizedBox(height: 12),
      RadioGroup<bool>(
        groupValue: all,
        onChanged: (v) => setState(() => _ids = v == true ? null : (_ids ?? {})),
        child: Column(children: [
          RadioListTile<bool>(value: true, title: Text(l.shareAll)),
          RadioListTile<bool>(
              value: false,
              title: Text(l.shareSelection(_ids?.length ?? 0))),
        ]),
      ),
      if (!all)
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(onPressed: _pick, child: Text(l.sharePick)),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _starting || (!all && _ids!.isEmpty) ? null : _start,
        icon: const Icon(Icons.wifi_tethering),
        label: Text(l.shareStart),
      ),
      if (_noNetwork)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(l.shareNoNetwork,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
    ]);
  }
}

class _Active extends StatelessWidget {
  const _Active({required this.info, required this.onStop});

  final ShareInfo info;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = 'http://${info.host}:${info.port}/?pin=${info.pin}';
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(l.shareActive, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Center(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: QrImageView(data: url, size: 200),
        ),
      ),
      const SizedBox(height: 16),
      ListTile(
        title: Text(l.shareAddress),
        subtitle: SelectableText('${info.host}:${info.port}',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      ListTile(
        title: Text(l.sharePin),
        subtitle: SelectableText(info.pin,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(letterSpacing: 4)),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: onStop,
        icon: const Icon(Icons.stop),
        label: Text(l.shareStop),
      ),
    ]);
  }
}
