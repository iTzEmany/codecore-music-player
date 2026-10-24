import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions.dart';
import '../core/platform.dart';
import 'folder_ops.dart';
import 'library_providers.dart';

/// Scans every folder, after the audio permission (the denial is remembered).
Future<void> scanWithPermission(WidgetRef ref) async {
  final ok = await ensureAudioPermission();
  ref.read(permissionDeniedProvider.notifier).set(!ok);
  if (!ok) return;
  await ref.read(scanStateProvider.notifier).scanAll();
}

/// The one «add folder» flow: pick, store, scan.
Future<void> addFolderAndScan(WidgetRef ref) async {
  final path = await FilePicker.getDirectoryPath();
  if (path == null) return;
  await ref.read(folderOpsProvider).add(path);
  await scanWithPermission(ref);
}

Future<void> addDefaultFolderAndScan(WidgetRef ref) async {
  final path = await defaultMusicDir();
  if (!await Directory(path).exists()) return;
  await ref.read(folderOpsProvider).add(path);
  await scanWithPermission(ref);
}
