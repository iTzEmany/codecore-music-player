import 'dart:convert';

import '../online/youtube_service.dart';
import 'track_matcher.dart';

/// A search result kept in the DB while the user has to choose.
class ImportCandidate {
  const ImportCandidate({
    required this.id,
    required this.title,
    required this.channel,
    this.durationSec,
    this.thumbnailUrl,
    this.score = 0,
    this.source = MediaSource.youtube,
    this.webpageUrl,
  });

  final String id, title, channel;
  final int? durationSec;
  final String? thumbnailUrl;
  final double score;
  final MediaSource source;
  final String? webpageUrl;

  factory ImportCandidate.fromScored(ScoredCandidate s) => ImportCandidate(
        id: s.result.id,
        title: s.result.title,
        channel: s.result.channel,
        durationSec: s.result.duration?.inSeconds,
        thumbnailUrl: s.result.thumbnailUrl,
        score: s.score,
        source: s.result.source,
        webpageUrl: s.result.webpageUrl,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'channel': channel,
        'durationSec': durationSec,
        'thumb': thumbnailUrl,
        'score': score,
        // Only for what is not YouTube: older rows stay as they were.
        if (source != MediaSource.youtube) 'src': source.name,
        if (webpageUrl != null) 'url': webpageUrl,
      };

  static ImportCandidate? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], title = j['title'];
    if (id is! String || title is! String) return null;
    return ImportCandidate(
      id: id,
      title: title,
      channel: '${j['channel'] ?? ''}',
      durationSec: (j['durationSec'] as num?)?.round(),
      thumbnailUrl: j['thumb'] as String?,
      score: (j['score'] as num?)?.toDouble() ?? 0,
      source: MediaSource.values.firstWhere(
        (m) => m.name == j['src'],
        orElse: () => MediaSource.youtube,
      ),
      webpageUrl: j['url'] as String?,
    );
  }

  YtResult toYtResult({String? downloadName}) => YtResult(
        id: id,
        title: title,
        channel: channel,
        duration: durationSec == null ? null : Duration(seconds: durationSec!),
        thumbnailUrl: thumbnailUrl,
        downloadName: downloadName,
        source: source,
        webpageUrl: webpageUrl,
      );
}

String encodeCandidates(List<ScoredCandidate> top) =>
    jsonEncode([for (final c in top) ImportCandidate.fromScored(c).toJson()]);

List<ImportCandidate> decodeCandidates(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final j = jsonDecode(raw);
    if (j is! List) return const [];
    return [
      for (final e in j) ?ImportCandidate.fromJson(e),
    ];
  } on FormatException {
    return const [];
  }
}
