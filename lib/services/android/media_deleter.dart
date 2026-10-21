import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/app_log.dart';

/// Asks the system to delete files the app did not create (Android 11+: a
/// plain `File.delete` is refused for them; MediaStore shows ONE dialog for
/// the whole batch). Returns the paths that are gone afterwards. Anything
/// that goes wrong (older Android, no channel, dialog refused) is logged and
/// means «nothing deleted».
Future<List<String>> deleteWithSystemDialog(List<String> paths) async {
  if (!Platform.isAndroid || paths.isEmpty) return const [];
  try {
    final gone = await const MethodChannel('codecore/media')
        .invokeListMethod<String>('deleteFiles', {'paths': paths});
    return gone ?? const [];
  } on Object catch (e, st) {
    AppLog.w('system delete failed for ${paths.length} file(s)', e, st);
    return const [];
  }
}
