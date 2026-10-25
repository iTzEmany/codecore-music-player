import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// Asks where to save [bytes] and writes them (Android SAF, desktop dialog).
/// Returns false when the user cancels.
Future<bool> saveBytes(String fileName, Uint8List bytes,
    {String mimeType = 'application/octet-stream'}) async {
  final uri = await FilePicker.saveFile(
      fileName: fileName, bytes: bytes, mimeType: mimeType);
  return uri != null;
}

const _saveChannel = MethodChannel('codecore/save');

/// Like [saveBytes] for a file on disk. On Android the file is streamed by
/// the platform side, never loaded in memory (it can be hundreds of MB).
Future<bool> saveFileAt(String fileName, String path,
    {String mimeType = 'application/octet-stream'}) async {
  if (Platform.isAndroid) {
    final saved = await _saveChannel.invokeMethod<bool>(
        'saveFile', {'path': path, 'name': fileName, 'mime': mimeType});
    return saved ?? false;
  }
  return saveBytes(fileName, await File(path).readAsBytes(), mimeType: mimeType);
}
