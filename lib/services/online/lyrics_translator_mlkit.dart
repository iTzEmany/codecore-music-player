import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../core/app_log.dart';
import 'lyrics_translator.dart';

/// ML Kit implementation (Android only). Models are fetched only when the user
/// asks, on any network (the dialog already warns about the size).
class MlKitLyricsTranslator implements LyricsTranslator {
  final _manager = OnDeviceTranslatorModelManager();
  OnDeviceTranslator? _current;
  String? _currentKey;

  @override
  Future<bool> isModelReady(String lang) => _manager.isModelDownloaded(lang);

  @override
  Future<void> downloadModel(String lang) async {
    final ok = await _manager.downloadModel(lang, isWifiRequired: false);
    if (!ok) throw StateError('model $lang not downloaded');
  }

  @override
  Future<void> deleteModel(String lang) async {
    // A translator that is open keeps its models in use.
    await close();
    // The plugin calls RemoteModelManager.deleteDownloadedModel on the
    // TranslateRemoteModel of [lang], which is the right call. ML Kit only
    // unregisters the model and removes its files lazily (its own cleanup
    // job, under no_backup/com.google.mlkit.translate.models), so the files
    // can stay for a while and a translation can still work meanwhile.
    final ok = await _manager.deleteModel(lang);
    if (!ok) throw StateError('model $lang not deleted');
  }

  @override
  Future<List<String>> translateLines(
    List<String> lines, {
    required String from,
    required String to,
  }) async {
    final t = await _translator(from, to);
    final out = <String>[];
    for (final line in lines) {
      out.add(await t.translateText(line));
    }
    return out;
  }

  Future<OnDeviceTranslator> _translator(String from, String to) async {
    final key = '$from>$to';
    final cur = _current;
    if (cur != null && _currentKey == key) return cur;
    await close();
    final src = TranslateLanguage.values.firstWhere((l) => l.bcpCode == from);
    final dst = TranslateLanguage.values.firstWhere((l) => l.bcpCode == to);
    _currentKey = key;
    return _current = OnDeviceTranslator(
      sourceLanguage: src,
      targetLanguage: dst,
    );
  }

  @override
  Future<void> close() async {
    final cur = _current;
    _current = null;
    _currentKey = null;
    if (cur == null) return;
    try {
      await cur.close();
    } on Object catch (e, st) {
      AppLog.w('translator close failed', e, st);
    }
  }
}
