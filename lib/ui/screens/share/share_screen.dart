import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import 'receive_tab.dart';
import 'send_tab.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key, this.initialTrackIds});

  /// Pre-selected tracks (from a track/album menu); null = choose inside.
  final List<int>? initialTrackIds;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.shareTitle),
          bottom: TabBar(tabs: [Tab(text: l.shareSend), Tab(text: l.shareReceive)]),
        ),
        body: Column(children: [
          if (Platform.isWindows)
            MaterialBanner(
              content: Text(l.shareFirewall),
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: TabBarView(children: [
              SendTab(initialTrackIds: initialTrackIds),
              const ReceiveTab(),
            ]),
          ),
        ]),
      ),
    );
  }
}
