import 'dart:async';
import 'dart:typed_data';

import 'package:codecore/providers/jam_broker_providers.dart';
import 'package:codecore/services/jam/remote/broker_entry.dart';
import 'package:codecore/services/jam/remote/mqtt_link.dart';
import 'package:codecore/ui/screens/settings/jam_remote_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// Echoes every publish back; [fail] makes connect throw.
class FakeMqttLink implements MqttLink {
  FakeMqttLink({this.fail = false});
  final bool fail;
  final _ctl = StreamController<MqttIncoming>.broadcast();
  bool disconnected = false;

  @override
  Future<void> connect(BrokerEntry broker) async {
    if (fail) throw StateError('bad certificate');
  }

  @override
  void subscribe(String topic) {}
  @override
  void unsubscribe(String topic) {}
  @override
  void publish(String topic, Uint8List bytes, {bool retain = false}) =>
      scheduleMicrotask(() => _ctl.add((topic: topic, payload: bytes)));
  @override
  Stream<MqttIncoming> get messages => _ctl.stream;
  @override
  bool get connected => true;
  @override
  void disconnect() => disconnected = true;
}

void main() {
  Future<Harness> open(WidgetTester t, {bool failLink = false, FakeMqttLink? link}) async {
    t.view.physicalSize = const Size(500, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await Harness.create(t);
    await h.pump(t, const JamRemoteSettings(), extraOverrides: [
      mqttLinkFactoryProvider.overrideWithValue(() => link ?? FakeMqttLink(fail: failLink)),
    ]);
    return h;
  }

  ProviderContainer box(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(JamRemoteSettings)));

  testWidgets('shows the defaults, adds a broker and an invalid one is refused', (t) async {
    final h = await open(t);
    expect(find.text('broker.emqx.io:8883'), findsOneWidget);
    expect(find.text('test.mosquitto.org:8886'), findsOneWidget);
    await t.tap(find.text('Aggiungi broker'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Indirizzo'), 'a b');
    await t.tap(find.text('Salva'));
    await t.pumpAndSettle();
    expect(find.text('Indirizzo o porta non validi'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'Indirizzo'), 'mio.broker.net');
    await t.tap(find.text('Salva'));
    await t.pumpAndSettle();
    expect(find.text('mio.broker.net:8883'), findsOneWidget);
    expect(box(t).read(jamBrokersProvider).length, 3);
    await h.dispose(t);
  });

  testWidgets('a broker without TLS is warned about, in the sheet and next to the entry', (t) async {
    final h = await open(t);
    await t.tap(find.text('Aggiungi broker'));
    await t.pumpAndSettle();
    expect(find.textContaining('Senza TLS'), findsNothing);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(find.textContaining('Senza TLS'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'Indirizzo'), 'plain.net');
    await t.tap(find.text('Salva'));
    await t.pumpAndSettle();
    expect(find.textContaining('Senza TLS'), findsOneWidget);
    await h.dispose(t);
  });

  testWidgets('moves a broker up, removes one and restores the defaults', (t) async {
    final h = await open(t);
    final c = box(t);
    await t.tap(find.byTooltip('Sposta su'));
    await t.pumpAndSettle();
    expect(c.read(jamBrokersProvider).first.host, 'test.mosquitto.org');
    await t.tap(find.byTooltip('Togli').first);
    await t.pumpAndSettle();
    expect(c.read(jamBrokersProvider).map((b) => b.host), ['broker.emqx.io']);
    await t.tap(find.text('Ripristina'));
    await t.pumpAndSettle();
    expect(c.read(jamBrokersProvider), kDefaultJamBrokers);
    await h.dispose(t);
  });

  testWidgets('Prova connessione: success and failure', (t) async {
    final link = FakeMqttLink();
    var h = await open(t, link: link);
    await t.tap(find.byTooltip('Prova connessione').first);
    await t.pumpAndSettle();
    expect(find.textContaining('connessione riuscita'), findsOneWidget);
    expect(link.disconnected, isTrue);
    await h.dispose(t);

    h = await open(t, failLink: true);
    await t.tap(find.byTooltip('Prova connessione').first);
    await t.pumpAndSettle();
    expect(find.textContaining('non riesco a collegarmi'), findsOneWidget);
    await h.dispose(t);
  });
}
