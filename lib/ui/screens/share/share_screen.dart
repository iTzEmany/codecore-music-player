import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../providers/share_hub.dart';
import '../../theme/tokens.dart';
import 'receive_tab.dart';
import 'send_tab.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key, this.initialTrackIds});

  /// Pre-selected tracks (from a track/album menu); null = choose inside.
  final List<int>? initialTrackIds;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  late final ShareHubNotifier _hub;

  @override
  void initState() {
    super.initState();
    // Captured now: `ref` must not be used from dispose().
    _hub = ref.read(shareHubProvider.notifier);
    _hub.enter();
  }

  @override
  void dispose() {
    // Leaving does not stop open outgoing offers: the hub keeps serving them.
    _hub.leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.shareTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.shareSend),
              Tab(text: l.shareReceive),
            ],
          ),
        ),
        body: Column(
          children: [
            if (Platform.isWindows)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cc.surface1,
                  borderRadius: BorderRadius.circular(CcDims.rCard),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: context.cc.accentSoft,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.shareFirewall)),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  SendTab(initialTrackIds: widget.initialTrackIds),
                  const ReceiveTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
