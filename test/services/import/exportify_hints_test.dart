import 'dart:io';

import 'package:codecore/services/import/exportify_hints.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('findExportifyDownload', () {
    late Directory dir;
    final tap = DateTime(2026, 10, 23, 12);

    setUp(() => dir = Directory.systemTemp.createTempSync('exportify_hints'));
    tearDown(() => dir.deleteSync(recursive: true));

    File make(String name, DateTime modified) {
      final f = File(p.join(dir.path, name))..writeAsStringSync('x');
      f.setLastModifiedSync(modified);
      return f;
    }

    test('takes the zip saved after the tap', () async {
      final f = make(
        'spotify_playlists.zip',
        tap.add(const Duration(minutes: 2)),
      );
      final found = await findExportifyDownload(
        dir,
        tap,
        tap.add(const Duration(minutes: 5)),
      );
      expect(found?.path, f.path);
    });

    test('takes the newest of several', () async {
      make('spotify_playlists.zip', tap.add(const Duration(minutes: 1)));
      final newer = make(
        'spotify_playlists (1).zip',
        tap.add(const Duration(minutes: 3)),
      );
      final found = await findExportifyDownload(
        dir,
        tap,
        tap.add(const Duration(minutes: 5)),
      );
      expect(found?.path, newer.path);
    });

    test('ignores a file older than the tap', () async {
      make('spotify_playlists.zip', tap.subtract(const Duration(minutes: 1)));
      expect(
        await findExportifyDownload(
          dir,
          tap,
          tap.add(const Duration(minutes: 5)),
        ),
        isNull,
      );
    });

    test('ignores other names', () async {
      make('holiday.zip', tap.add(const Duration(minutes: 1)));
      make('spotify_playlists.txt', tap.add(const Duration(minutes: 1)));
      expect(
        await findExportifyDownload(
          dir,
          tap,
          tap.add(const Duration(minutes: 5)),
        ),
        isNull,
      );
    });

    test('takes a renamed csv too', () async {
      final f = make('my playlists.csv', tap.add(const Duration(minutes: 1)));
      expect(
        (await findExportifyDownload(
          dir,
          tap,
          tap.add(const Duration(minutes: 5)),
        ))?.path,
        f.path,
      );
    });

    test('gives nothing after 30 minutes', () async {
      make('spotify_playlists.zip', tap.add(const Duration(minutes: 1)));
      expect(
        await findExportifyDownload(
          dir,
          tap,
          tap.add(const Duration(minutes: 31)),
        ),
        isNull,
      );
    });

    test('a missing folder gives nothing', () async {
      expect(
        await findExportifyDownload(
          Directory(p.join(dir.path, 'no')),
          tap,
          tap,
        ),
        isNull,
      );
    });
  });

  group('exportifyReminderDue', () {
    final now = DateTime(2026, 10, 23, 12);
    final ms = now.millisecondsSinceEpoch;
    final day = const Duration(days: 1).inMilliseconds;

    test('off is never due', () {
      expect(
        exportifyReminderDue(
          remindDays: 0,
          lastSyncAt: null,
          snoozeUntil: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('due when the last sync is older than the interval', () {
      expect(
        exportifyReminderDue(
          remindDays: 7,
          lastSyncAt: ms - 8 * day,
          snoozeUntil: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('not due before the interval has passed', () {
      expect(
        exportifyReminderDue(
          remindDays: 7,
          lastSyncAt: ms - 3 * day,
          snoozeUntil: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('snoozed stays quiet, then is due again', () {
      expect(
        exportifyReminderDue(
          remindDays: 7,
          lastSyncAt: ms - 8 * day,
          snoozeUntil: ms + day,
          now: now,
        ),
        isFalse,
      );
      expect(
        exportifyReminderDue(
          remindDays: 7,
          lastSyncAt: ms - 8 * day,
          snoozeUntil: ms - 1,
          now: now,
        ),
        isTrue,
      );
    });

    test('never synced is due', () {
      expect(
        exportifyReminderDue(
          remindDays: 14,
          lastSyncAt: null,
          snoozeUntil: null,
          now: now,
        ),
        isTrue,
      );
    });
  });
}
