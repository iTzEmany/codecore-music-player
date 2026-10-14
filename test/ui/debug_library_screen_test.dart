import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/data/repositories/track_repository.dart';
import 'package:codecore/providers/player_providers.dart';
import 'package:codecore/services/audio/codecore_audio_handler.dart';
import 'package:codecore/services/audio/play_queue.dart';
import 'package:codecore/ui/screens/debug_library_screen.dart';
import '../support/fake_backend.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debug screen builds and shows empty state', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final handler = CodecoreAudioHandler(
        FakeBackend(), PlayQueue(), TrackRepository(db),
        onError: (_) {});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        audioHandlerProvider.overrideWithValue(handler),
        coversDirProvider.overrideWith((ref) async => Directory.systemTemp),
      ],
      child: const MaterialApp(home: DebugLibraryScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Scegli cartella'), findsOneWidget);
    expect(find.text('Scansiona'), findsOneWidget);
    expect(find.textContaining('Nessun brano'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await tester.runAsync(() async {
      await handler.dispose();
      await db.close();
    });
  });
}
