import 'dart:async';

import 'package:codecore/providers/jam_providers.dart';
import 'package:codecore/providers/share_hub.dart';
import 'package:codecore/providers/speaker_providers.dart';
import 'package:codecore/services/audio/bluetooth_outputs.dart';
import 'package:codecore/services/audio/speaker_monitor.dart';
import 'package:codecore/services/jam/jam_models.dart';
import 'package:codecore/services/jam/speaker_jam.dart';
import 'package:codecore/services/share/discovery.dart';
import 'package:codecore/ui/screens/devices/devices_sheet.dart';
import 'package:codecore/ui/screens/jam/speaker_notices.dart';
import 'package:codecore/ui/screens/jam/speaker_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

const _host = Peer(
  id: 'h1',
  name: 'Telefono di Ale',
  host: '10.0.0.5',
  port: 8000,
  platform: 'android',
  jamName: 'Cucina',
);

class _Hub extends ShareHubNotifier {
  @override
  ShareHubState build() => const ShareHubState(active: true, peers: [_host]);
  void setPeers(List<Peer> p) => state = state.copyWith(peers: p);
  @override
  Future<void> enter() async {}
  @override
  Future<void> leave() async {}
}

class _Jam extends JamController {
  _Jam([this.initial = const JamUiState()]);
  final JamUiState initial;
  final requested = <String>[];
  var opened = 0;
  @override
  JamUiState build() => initial;
  @override
  Future<void> request(Peer peer) async => requested.add(peer.id);
  @override
  Future<void> openSpeakerJam() async => opened++;
}

Future<void> _app(WidgetTester t, Harness h, _Hub hub, _Jam jam) => h.pump(
  t,
  const Scaffold(
    body: Column(
      children: [JamInviteBanner(), SpeakerAwayNotice()],
    ),
  ),
  extraOverrides: [
    shareHubProvider.overrideWith(() => hub),
    jamProvider.overrideWith(() => jam),
  ],
);

void main() {
  testWidgets('banner: tap asks to join', (t) async {
    final h = await Harness.create(t);
    final jam = _Jam();
    await _app(t, h, _Hub(), jam);
    await t.tap(find.text('Unisciti alla Jam di Cucina'));
    await t.pump();
    expect(jam.requested, ['h1']);
    await t.pumpAndSettle();
    await h.dispose(t);
  });

  testWidgets('banner: X hides it for that Jam, the end of the announcement removes it', (t) async {
    final h = await Harness.create(t);
    final hub = _Hub();
    await _app(t, h, hub, _Jam());
    expect(find.text('Unisciti alla Jam di Cucina'), findsOneWidget);
    await t.tap(find.byTooltip('Nascondi'));
    await t.pump();
    expect(find.textContaining('Unisciti'), findsNothing);
    // Same Jam again: still hidden. Another Jam name: back.
    hub.setPeers([_host]);
    await t.pump();
    expect(find.textContaining('Unisciti'), findsNothing);
    hub.setPeers([
      const Peer(id: 'h1', name: 'Telefono di Ale', host: '10.0.0.5', port: 8000, platform: 'android', jamName: 'Salotto'),
    ]);
    await t.pump();
    expect(find.text('Unisciti alla Jam di Salotto'), findsOneWidget);
    // The announcement stops: gone.
    hub.setPeers([
      const Peer(id: 'h1', name: 'Telefono di Ale', host: '10.0.0.5', port: 8000, platform: 'android'),
    ]);
    await t.pump();
    expect(find.textContaining('Unisciti'), findsNothing);
    await h.dispose(t);
  });

  testWidgets('banner: not shown while in a Jam', (t) async {
    final h = await Harness.create(t);
    await _app(t, h, _Hub(), _Jam(const JamUiState(phase: JamPhase.requesting)));
    expect(find.textContaining('Unisciti'), findsNothing);
    await h.dispose(t);
  });

  testWidgets('Dispositivi: first row joins the announced Jam', (t) async {
    final h = await Harness.create(t);
    final jam = _Jam();
    await h.pump(
      t,
      Builder(builder: (c) => TextButton(onPressed: () => DevicesSheet.show(c), child: const Text('open'))),
      extraOverrides: [
        shareHubProvider.overrideWith(_Hub.new),
        jamProvider.overrideWith(() => jam),
      ],
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Unisciti alla Jam di Cucina'));
    await t.pump();
    expect(jam.requested, ['h1']);
    await h.dispose(t);
  });

  testWidgets('away notice: shown for everyone while the speaker is missing', (t) async {
    final h = await Harness.create(t);
    final away = JamUiState(
      phase: JamPhase.active,
      role: JamRole.guest,
      jam: const JamState(version: 1, hostDeviceId: 'host', outputDeviceId: 'host', speaker: true, speakerAwaySince: 5),
    );
    await _app(t, h, _Hub(), _Jam(away));
    expect(find.text('Collega una cassa'), findsOneWidget);
    await h.dispose(t);
  });

  testWidgets('offer sheet: Si accepts the offer', (t) async {
    final h = await Harness.create(t);
    final port = _Port();
    final sj = SpeakerJam(
      speakerConnected: const Stream.empty(),
      connected: () => true,
      enabled: () => true,
      port: port,
    );
    await h.pump(
      t,
      Builder(builder: (c) => TextButton(onPressed: () => showSpeakerOffer(c, sj), child: const Text('open'))),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Suonare la Jam sulla tua cassa?'), findsOneWidget);
    await t.tap(find.text('Sì'));
    await t.pumpAndSettle();
    expect(port.sent, [JamCommandType.offerSpeaker]);
    await h.dispose(t);
  });

  testWidgets('wiring: switching the setting refreshes the speaker Jam', (t) async {
    final h = await Harness.create(t);
    SharedPreferences.setMockInitialValues({'speakerJam.enabled': false});
    final m = SpeakerMonitor(
      fetch: () async => const BluetoothSnapshot(
        permission: true,
        outputs: [BluetoothOutput(name: 'JBL', address: 'a', deviceClass: 0x0414)],
      ),
      changed: const Stream.empty(),
      seen: const Stream.empty(),
      active: () async => false,
      request: () async => true,
    );
    await t.runAsync(m.start);
    final jam = _Jam();
    await h.pump(
      t,
      Consumer(builder: (c, ref, _) {
        ref.watch(speakerJamProvider);
        ref.watch(speakerChangesProvider);
        return const SizedBox();
      }),
      extraOverrides: [
        speakerMonitorProvider.overrideWithValue(m),
        jamProvider.overrideWith(() => jam),
      ],
    );
    expect(jam.opened, 0);
    await t.runAsync(() => m.setEnabled(true));
    await t.pump();
    expect(jam.opened, 1);
    await h.dispose(t);
  });

  testWidgets('banner: hiding the first invite shows the second', (t) async {
    final h = await Harness.create(t);
    await _app(t, h, _Jams(), _Jam());
    expect(find.text('Unisciti alla Jam di Cucina'), findsOneWidget);
    await t.tap(find.byTooltip('Nascondi'));
    await t.pump();
    expect(find.text('Unisciti alla Jam di Studio'), findsOneWidget);
    await h.dispose(t);
  });

  testWidgets('banner: a hidden Jam that stops and starts again invites again', (t) async {
    final h = await Harness.create(t);
    final hub = _Hub();
    await _app(t, h, hub, _Jam());
    await t.tap(find.byTooltip('Nascondi'));
    await t.pump();
    hub.setPeers([const Peer(id: 'h1', name: 'Telefono di Ale', host: '10.0.0.5', port: 8000, platform: 'android')]);
    await t.pump();
    await t.pump();
    hub.setPeers([_host]);
    await t.pump();
    expect(find.text('Unisciti alla Jam di Cucina'), findsOneWidget);
    await h.dispose(t);
  });

  testWidgets('offer: true, false, true leaves one sheet and the old one is closed unanswered', (t) async {
    final h = await Harness.create(t);
    final sj = _offerJam(_Port());
    await _openerFor(t, h, (c) => showSpeakerOffer(c, sj));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Suonare la Jam sulla tua cassa?'), findsOneWidget);
    closeSpeakerOffer();
    await t.pumpAndSettle();
    expect(find.text('Suonare la Jam sulla tua cassa?'), findsNothing);
    expect(sj.offerPending.value, isTrue); // closed by us, not declined
    await t.tap(find.text('open'));
    await t.tap(find.text('open'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('Suonare la Jam sulla tua cassa?'), findsOneWidget);
    closeSpeakerOffer();
    await t.pumpAndSettle();
    await h.dispose(t);
  });

  testWidgets('offer: waits for an open dialog to close', (t) async {
    final h = await Harness.create(t);
    final sj = _offerJam(_Port());
    late BuildContext ctx;
    await _openerFor(t, h, (c) {
      ctx = c;
      showDialog<void>(context: c, builder: (_) => const AlertDialog(title: Text('Dialogo')));
    });
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    showSpeakerOffer(ctx, sj);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Suonare la Jam sulla tua cassa?'), findsNothing);
    Navigator.of(ctx).pop();
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(find.text('Suonare la Jam sulla tua cassa?'), findsOneWidget);
    closeSpeakerOffer();
    await t.pumpAndSettle();
    await h.dispose(t);
  });

  testWidgets('offer: swiping the sheet away declines it', (t) async {
    final h = await Harness.create(t);
    final sj = _offerJam(_Port());
    await _openerFor(t, h, (c) => showSpeakerOffer(c, sj));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(find.text('Suonare la Jam sulla tua cassa?'), findsNothing);
    expect(sj.offerPending.value, isFalse);
    await h.dispose(t);
  });
}

class _Jams extends _Hub {
  @override
  ShareHubState build() => const ShareHubState(
    active: true,
    peers: [
      _host,
      Peer(id: 'h2', name: 'Tablet', host: '10.0.0.6', port: 8000, platform: 'android', jamName: 'Studio'),
    ],
  );
}

SpeakerJam _offerJam(_Port port) => SpeakerJam(
  speakerConnected: const Stream.empty(),
  connected: () => true,
  enabled: () => true,
  port: port,
);

Future<void> _openerFor(WidgetTester t, Harness h, void Function(BuildContext) f) => h.pump(
  t,
  Builder(builder: (c) => TextButton(onPressed: () => f(c), child: const Text('open'))),
);


class _Port implements SpeakerJamPort {
  final sent = <JamCommandType>[];
  @override
  SpeakerJamView get view => const SpeakerJamView(role: SpeakerRole.guest, speaker: true, awaySince: 1);
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<void> open() async {}
  @override
  Future<void> closeSilently() async {}
  @override
  Future<void> send(JamCommand cmd) async => sent.add(cmd.type);
  @override
  Future<void> end() async {}
}
