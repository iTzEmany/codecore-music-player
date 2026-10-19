import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/l10n/app_localizations.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/data/settings/settings_store.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/providers/settings_providers.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/ui/theme/app_theme.dart';
import 'package:codecore/ui/theme/tokens.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

class Harness {
  Harness._(this.db, this.handler, this.backend, this.store);

  final AppDatabase db;
  final CodecoreAudioHandler handler;
  final FakeBackend backend;
  final SettingsStore store;

  /// Overridable before `pump`: where cover files are looked up.
  Directory coversDir = Directory.systemTemp;

  static Future<Harness> create(WidgetTester tester, {int tracks = 0}) async {
    SharedPreferences.setMockInitialValues({});
    final store = await SettingsStore.open();
    final db = AppDatabase(NativeDatabase.memory());
    final backend = FakeBackend();
    final handler = CodecoreAudioHandler(backend, PlayQueue(), TrackRepository(db),
        onError: (_) {});
    for (var i = 0; i < tracks; i++) {
      await db.into(db.tracks).insert(TracksCompanion.insert(
            path: '/m/t$i.mp3',
            title: 'Song $i',
            albumKey: 'artist|album ${i % 2}',
            format: 'mp3',
            sizeBytes: 1,
            mtimeMs: 1,
            addedAt: i,
            artist: const Value('Artist'),
            album: Value('Album ${i % 2}'),
            durationMs: const Value(185000),
          ));
    }
    return Harness._(db, handler, backend, store);
  }

  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        audioHandlerProvider.overrideWithValue(handler),
        settingsStoreProvider.overrideWithValue(store),
        coversDirProvider.overrideWithValue(coversDir),
      ];

  Future<void> pump(WidgetTester tester, Widget child,
      {List<Override> extraOverrides = const [],
      Locale locale = const Locale('it')}) async {
    await tester.pumpWidget(
        ProviderScope(
        overrides: [...overrides, ...extraOverrides],
        child: MaterialApp(
          theme: buildThemeFromColors(CcColors.notte, false),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.runAsync(() async {
      await handler.dispose();
      await db.close();
    });
  }
}
