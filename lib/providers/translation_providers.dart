import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_log.dart';
import '../core/platform.dart';
import '../services/online/lyrics_translator.dart';
import '../services/online/lyrics_translator_mlkit.dart';

/// The on-device translator, or null where there is none (everything but
/// Android): the UI hides every translation entry then.
final lyricsTranslatorProvider = Provider<LyricsTranslator?>((ref) {
  if (!isAndroid) return null;
  final t = MlKitLyricsTranslator();
  ref.onDispose(t.close);
  return t;
});

/// Translated lyrics of one track, line by line (same order as the original).
class LyricsTranslation {
  const LyricsTranslation({
    required this.trackId,
    required this.synced,
    required this.lines,
  });

  final int trackId;

  /// True when [lines] line up with the timed (LRC) lines.
  final bool synced;
  final List<String> lines;
}

class LyricsTranslationNotifier extends Notifier<LyricsTranslation?> {
  @override
  LyricsTranslation? build() => null;

  /// Translates [lines] and shows the result for [trackId]. Returns false on
  /// failure (logged), leaving any previous translation in place.
  Future<bool> translate({
    required int trackId,
    required bool synced,
    required List<String> lines,
    required String from,
    required String to,
  }) async {
    final translator = ref.read(lyricsTranslatorProvider);
    if (translator == null) return false;
    try {
      final out = await translateKeepingLayout(
        translator,
        lines,
        from: from,
        to: to,
      );
      state = LyricsTranslation(trackId: trackId, synced: synced, lines: out);
      return true;
    } on Object catch (e, st) {
      AppLog.e('lyrics translation failed', e, st);
      return false;
    }
  }

  void clear() => state = null;
}

final lyricsTranslationProvider =
    NotifierProvider<LyricsTranslationNotifier, LyricsTranslation?>(
      LyricsTranslationNotifier.new,
    );
