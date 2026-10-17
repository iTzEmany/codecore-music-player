import '../../core/audio_format.dart';
import '../../l10n/app_localizations.dart';

import '../../data/db/app_database.dart';

/// «512 B», «842 KB», «12.4 MB», «1.2 GB» (decimal point; the unit is universal).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
}

String formatDuration(int ms) {
  if (ms <= 0) return '0:00';
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// Quality text per docs/04 §8; never invents missing values.
String qualityLabel(Track t) {
  final fmt = t.format.toUpperCase();
  if (isLosslessFormat(t.format)) {
    final parts = <String>[];
    if (t.bitDepth != null) parts.add('${t.bitDepth} bit');
    if (t.sampleRateHz != null) {
      final khz = t.sampleRateHz! / 1000;
      final text = khz == khz.roundToDouble()
          ? khz.toStringAsFixed(0)
          : khz.toStringAsFixed(1);
      parts.add('$text kHz');
    }
    return parts.isEmpty ? fmt : '$fmt • ${parts.join(' / ')}';
  }
  return t.bitrateKbps == null ? fmt : '$fmt • ${t.bitrateKbps} kbps';
}

/// «circa 18 min», «circa 2 h 10 min», «meno di 1 min».
String etaLabel(AppLocalizations l, Duration d) {
  final minutes = (d.inSeconds / 60).round();
  if (minutes < 1) return l.etaLessThanMinute;
  if (minutes >= 60) return l.etaHours(minutes ~/ 60, minutes % 60);
  return l.etaMinutes(minutes);
}
