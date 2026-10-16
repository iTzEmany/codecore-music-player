import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Asks where to save [bytes] and writes them (Android SAF, desktop dialog).
/// Returns false when the user cancels.
Future<bool> saveBytes(String fileName, Uint8List bytes,
    {String mimeType = 'application/octet-stream'}) async {
  final uri = await FilePicker.saveFile(
      fileName: fileName, bytes: bytes, mimeType: mimeType);
  return uri != null;
}
