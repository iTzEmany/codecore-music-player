import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_log.dart';
import '../core/platform.dart';
import '../l10n/app_localizations.dart';
import '../services/import/import_chain.dart';
import '../services/import/playlist_import_service.dart';
import '../services/online/download_queue.dart';
import '../ui/screens/import/import_labels.dart';
import '../ui/widgets/format_utils.dart';
import 'database_providers.dart';
import 'import_providers.dart';
import 'settings_providers.dart';
import 'youtube_providers.dart';

/// What the notification that keeps the app alive says.
typedef BackgroundWork = ({String title, String text, int done, int total, String? pause});

/// The import that runs (counted as a whole), else the downloads waiting or
/// running; null when there is nothing to keep the app alive for. While the
/// engine [wait]s (rate limit, no network) the notification says until when.
BackgroundWork? backgroundWork(
  AppLocalizations l, {
  required List<ImportProgress> imports,
  required List<DownloadItem> downloads,
  ImportWait? wait,
}) {
  final running = imports.where((i) => !i.paused && i.done < i.total).firstOrNull;
  if (running != null) {
    final eta = running.eta;
    return (
      title: l.logImport(running.name),
      text: l.importNotificationText(running.saved, running.total) +
          (wait != null
              ? ' · ${importWaitLabel(l, wait)}'
              : eta == null
                  ? ''
                  : ' · ${etaLabel(l, eta)}'),
      done: running.done,
      total: running.total,
      pause: l.csvImportPause,
    );
  }
  final active = downloads
      .where((d) =>
          d.status == DownloadStatus.queued ||
          d.status == DownloadStatus.downloading ||
          d.status == DownloadStatus.waitingRetry)
      .length;
  if (active == 0) return null;
  return (
    title: l.downloadsNotificationTitle,
    text: l.downloadsNotificationText(active),
    done: 0,
    total: 0,
    pause: null,
  );
}

const _channel = MethodChannel('codecore/import');

/// Android: the foreground service and its notification follow what runs, at
/// most once a second; «Pausa» on it pauses the imports; a finished import
/// leaves a summary. Watched once, from the app root.
final importNotificationProvider = Provider<void>((ref) {
  if (!isAndroid) return;
  AppLocalizations l10n() => lookupAppLocalizations(Locale(ref.read(settingsProvider).language));
  BackgroundWork? shown;
  var asked = false;
  Timer? timer;

  Future<void> send() async {
    timer = null;
    final work = backgroundWork(l10n(),
        imports: ref.read(importProgressProvider),
        downloads: ref.read(downloadsProvider),
        wait: ref.read(importWaitProvider).value);
    if (work == shown) return;
    shown = work;
    try {
      if (work == null) {
        await _channel.invokeMethod<void>('stop');
        return;
      }
      if (!asked) {
        asked = true;
        // Without it the notification is hidden; the service runs anyway.
        await Permission.notification.request();
      }
      await _channel.invokeMethod<void>('show', {
        'title': work.title,
        'text': work.text,
        'done': work.done,
        'total': work.total,
        'pause': work.pause,
      });
    } on Object catch (e, st) {
      AppLog.w('import notification not updated', e, st);
    }
  }

  void schedule() => timer ??= Timer(const Duration(seconds: 1), () => unawaited(send()));

  ref.listen(importProgressProvider, (_, _) => schedule());
  ref.listen(downloadsProvider, (_, _) => schedule());
  ref.listen(importWaitProvider, (_, _) => schedule());
  ref.listen<AsyncValue<ImportEvent>>(importEventsProvider, (_, e) {
    final event = e.value;
    if (event == null) return;
    if (event.kind == ImportEventKind.completed) {
      unawaited(_finished(ref, l10n(), event.importId));
    } else {
      // Stopped by itself: say so, the ongoing notification goes away.
      final why = importStopText(l10n(), event.kind);
      if (why != null) unawaited(_paused(ref, l10n(), event.importId, why));
    }
  });
  _channel.setMethodCallHandler((call) async {
    if (call.method != 'pause') return;
    final svc = ref.read(playlistImportServiceProvider);
    for (final p in ref.read(importProgressProvider)) {
      if (!p.paused) await svc.pauseChain(p.id);
    }
  });
  ref.onDispose(() {
    timer?.cancel();
    _channel.setMethodCallHandler(null);
  });
});

Future<void> _paused(Ref ref, AppLocalizations l, int importId, String why) async {
  try {
    final imp = await ref.read(importRepositoryProvider).get(importId);
    await _channel.invokeMethod<void>('finished', {
      'title': l.importPausedTitle(imp == null ? '' : importLabel(imp.sourceName)),
      'text': why,
    });
  } on Object catch (e, st) {
    AppLog.w('import pause notice not shown', e, st);
  }
}

Future<void> _finished(Ref ref, AppLocalizations l, int importId) async {
  try {
    // From the database: the screens' providers may not be listening now.
    final blocks = await ref.read(playlistImportServiceProvider).chainOf(importId);
    final repo = ref.read(importRepositoryProvider);
    final items = {for (final b in blocks) b.id: await repo.items(b.id)};
    final p = ImportProgress.chain(blocks, (id) => items[id] ?? const []);
    await _channel.invokeMethod<void>('finished', {
      'title': l.logImport(p.name),
      'text': l.csvImportDone(p.done - p.review - p.missing - p.planned, p.review, p.missing),
    });
  } on Object catch (e, st) {
    AppLog.w('import summary not shown', e, st);
  }
}
