/// Languages offered for lyrics translation (BCP-47 codes known to ML Kit),
/// with their own names: a menu in the user's language would need 20 more
/// strings per locale for no gain.
const Map<String, String> translationLanguages = {
  'en': 'English',
  'it': 'Italiano',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'pt': 'Português',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'ru': 'Русский',
  'uk': 'Українська',
  'tr': 'Türkçe',
  'ar': 'العربية',
  'ja': '日本語',
  'ko': '한국어',
  'zh': '中文',
  'sv': 'Svenska',
  'ro': 'Română',
  'cs': 'Čeština',
  'el': 'Ελληνικά',
  'hi': 'हिन्दी',
};

/// Approximate size of one language model, shown before downloading.
const int translationModelMegabytes = 30;

/// On-device translation (the text never leaves the phone). Languages are
/// BCP-47 codes from [translationLanguages].
abstract class LyricsTranslator {
  Future<bool> isModelReady(String lang);

  /// Downloads the model; throws if it fails (no network, no space).
  Future<void> downloadModel(String lang);

  Future<void> deleteModel(String lang);

  /// One output per input line, same order.
  Future<List<String>> translateLines(
    List<String> lines, {
    required String from,
    required String to,
  });

  /// Releases the native translators.
  Future<void> close();
}

/// Translates [lines] keeping the layout: blank lines (instrumental breaks,
/// stanza gaps) and lines with no letters (e.g. "♪") are passed through, so
/// the result lines up one to one with the timed lyrics.
Future<List<String>> translateKeepingLayout(
  LyricsTranslator translator,
  List<String> lines, {
  required String from,
  required String to,
}) async {
  if (from == to) return List.of(lines);
  final indexes = [
    for (var i = 0; i < lines.length; i++)
      if (_hasLetters(lines[i])) i,
  ];
  if (indexes.isEmpty) return List.of(lines);
  final translated = await translator.translateLines(
    [for (final i in indexes) lines[i].trim()],
    from: from,
    to: to,
  );
  if (translated.length != indexes.length) {
    throw StateError(
      'translator returned ${translated.length} lines for ${indexes.length}',
    );
  }
  final out = List.of(lines);
  for (var k = 0; k < indexes.length; k++) {
    out[indexes[k]] = translated[k];
  }
  return out;
}

final _letter = RegExp(r'\p{L}', unicode: true);

bool _hasLetters(String s) => _letter.hasMatch(s);
