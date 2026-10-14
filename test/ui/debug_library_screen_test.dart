import 'dart:io';

import 'package:codecore/data/db/app_database.dart';
import 'package:codecore/providers/database_providers.dart';
import 'package:codecore/providers/library_providers.dart';
import 'package:codecore/ui/screens/debug_library_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debug screen builds and shows empty state', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
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
    await tester.runAsync(db.close);
  });
}
