import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'core/app_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.i('avvio');
  if (Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized();
  }
  runApp(const ProviderScope(child: CodecoreApp()));
}
