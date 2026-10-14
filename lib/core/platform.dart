import 'dart:io';

bool get isAndroid => Platform.isAndroid;
bool get isDesktop =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

Future<String> defaultMusicDir() async {
  if (Platform.isAndroid) return '/storage/emulated/0/Music';
  if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE'] ?? '';
    return '$profile\\Music';
  }
  final home = Platform.environment['HOME'] ?? '';
  return '$home/Music';
}
