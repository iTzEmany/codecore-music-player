import 'dart:ui';

import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/providers/import_notification_providers.dart';
import 'package:codecore/providers/import_providers.dart';
import 'package:codecore/services/online/download_queue.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/import/playlist_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

ImportProgress _imp({bool paused = false, int done = 349, int total = 2253}) => ImportProgress(
      id: 26,
      playlistId: 4,
      name: 'Liked Songs',
      total: total,
      done: done,
      saved: done - 2,
      review: 0,
      missing: 0,
      paused: paused,
      eta: const Duration(hours: 2),
    );

DownloadItem _dl(DownloadStatus s) => DownloadItem(
    id: 1, result: const YtResult(id: 'v', title: 'T', channel: 'C', duration: null), status: s);

void main() {
  final l = lookupAppLocalizations(const Locale('it'));

  test('a running import: the songs saved, with the time left and «Pausa»', () {
    final w = backgroundWork(l, imports: [_imp()], downloads: const [])!;
    expect(w.title, 'Importazione «Liked Songs»');
    expect(w.text, startsWith('347 di 2253, '));
    expect((w.done, w.total, w.pause), (349, 2253, 'Pausa'));
  });

  test('while the engine waits the notification says until when, not the time left', () {
    final w = backgroundWork(l,
        imports: [_imp()],
        downloads: const [],
        wait: (reason: ImportEventKind.rateLimited, until: DateTime(2026, 10, 21, 4, 32)))!;
    expect(w.text, '347 di 2253, YouTube chiede una pausa: riprendo alle 04:32');
    final n = backgroundWork(l,
        imports: [_imp()],
        downloads: const [],
        wait: (reason: ImportEventKind.network, until: DateTime(2026, 10, 21, 4, 5)))!;
    expect(n.text, endsWith('Rete assente: riprovo alle 04:05'));
  });

  test('no import running: the downloads keep the app alive; nothing left: no notification', () {
    final w = backgroundWork(l,
        imports: [_imp(paused: true)],
        downloads: [_dl(DownloadStatus.downloading), _dl(DownloadStatus.queued), _dl(DownloadStatus.done)])!;
    expect(w.title, 'Download in corso');
    expect(w.text, '2 brani');
    expect(w.pause, isNull);
    expect(backgroundWork(l, imports: [_imp(paused: true)], downloads: [_dl(DownloadStatus.done)]), isNull);
    expect(backgroundWork(l, imports: [_imp(done: 10, total: 10)], downloads: const []), isNull,
        reason: 'all rows done');
  });
}
