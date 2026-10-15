import 'package:codecore/services/share/offers.dart';
import 'package:codecore/ui/screens/share/incoming_offer_dialog.dart';
import 'package:codecore/ui/screens/share/share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('share screen lists the nearby section and manual option',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, tracks: 2);
    await h.pump(tester, const ShareScreen());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dispositivi vicini'), findsOneWidget);
    expect(find.text('Collegamento manuale (IP e PIN)'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('incoming offer dialog offers accept and decline',
      (tester) async {
    final h = await Harness.create(tester);
    final offer = IncomingOffer(
      offerId: 'o1',
      fromId: 'dev',
      fromName: 'Telefono di Anna',
      fromHost: '192.168.1.9',
      fromPort: 4000,
      token: 'tok-12345678',
      items: const [
        OfferItem(id: 1, title: 'Song', artist: 'Band', sizeBytes: 3000000, ext: 'mp3'),
      ],
    );
    await h.pump(tester, IncomingOfferDialog(offer: offer));
    expect(find.textContaining('Telefono di Anna'), findsOneWidget);
    expect(find.text('Accetta'), findsOneWidget);
    expect(find.text('Rifiuta'), findsOneWidget);
    await h.dispose(tester);
  });
}
