import 'package:codecore/core/issue_report.dart';
import 'package:codecore/providers/issue_providers.dart';
import 'package:codecore/services/issue/link_opener.dart';
import 'package:codecore/ui/screens/settings/report_issue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

class _FakeOpener extends LinkOpener {
  final opened = <String>[];
  bool ok = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return ok;
  }
}

const _info = TechInfo(
  appVersion: '1.2.0',
  buildNumber: '6053',
  platform: 'android',
  osVersion: '14',
  deviceModel: 'Mi A3',
  flavor: 'completa',
  transition: 'normal',
  shufflePlus: false,
  language: 'it',
  logLines: ['2026 [W] qualcosa'],
);

void main() {
  testWidgets('validation, preview toggle, open and copy', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opener = _FakeOpener();
    String? clip;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (c) async {
        if (c.method == 'Clipboard.setData') {
          clip = (c.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final h = await Harness.create(tester);
    await h.pump(
      tester,
      const ReportIssueScreen(),
      extraOverrides: [
        linkOpenerProvider.overrideWithValue(opener),
        issueTechInfoProvider.overrideWith((ref) async => _info),
      ],
    );

    FilledButton openBtn() =>
        tester.widget(find.byKey(const ValueKey('report-open')));
    expect(openBtn().onPressed, isNull, reason: 'empty fields');
    expect(find.byKey(const ValueKey('report-preview')), findsOneWidget);
    expect(find.textContaining('Mi A3'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('report-title')),
      'Si ferma',
    );
    await tester.enterText(
      find.byKey(const ValueKey('report-description')),
      'corta',
    );
    await tester.pump();
    expect(openBtn().onPressed, isNull, reason: 'description too short');

    await tester.enterText(
      find.byKey(const ValueKey('report-description')),
      'La musica si ferma dopo dieci minuti',
    );
    await tester.pump();
    expect(openBtn().onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('report-open')));
    await tester.pump();
    expect(opener.opened.single, contains('issues/new?title=Si%20ferma'));
    expect(opener.opened.single, contains('Mi%20A3'));

    await tester.tap(find.byKey(const ValueKey('report-copy')));
    await tester.pump();
    expect(clip, startsWith('Si ferma\n\nLa musica si ferma'));
    expect(clip, contains('Mi A3'));

    await tester.tap(find.byKey(const ValueKey('report-attach')));
    await tester.pump();
    expect(find.byKey(const ValueKey('report-preview')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('report-copy')));
    await tester.pump();
    expect(clip, isNot(contains('Mi A3')));

    opener.ok = false;
    clip = null;
    await tester.tap(find.byKey(const ValueKey('report-open')));
    await tester.pump();
    expect(clip, isNotNull, reason: 'browser failure falls back to copying');
    await h.dispose(tester);
  });
}
