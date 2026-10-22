import 'dart:convert';
import 'dart:io';

import 'package:codecore/services/online/query_match.dart';
import 'package:codecore/services/online/search_cache.dart';
import 'package:codecore/services/online/youtube_service.dart';
import 'package:codecore/services/online/ytm_artist.dart';
import 'package:codecore/services/online/ytm_artist_parser.dart';

/// One recorded search (2026-10-22): what YouTube Music and YouTube answered
/// and the card, as `test/fixtures/smart_search/cases.json` keeps them.
class SmartCase {
  SmartCase(Map j)
      : query = j['query'] as String,
        group = j['group'] as String,
        expectedFirst = (j['expectedFirst'] as List?)?.cast<String>(),
        intent = j['intent'] as String?,
        songs = [for (final s in j['songs'] as List) ytResultFromJson(s)!],
        videos = [for (final s in j['videos'] as List) ytResultFromJson(s)!],
        card = parseTopCard(j['card'] as Map);

  final String query, group;

  /// The ids that are an acceptable first result; null where the case is about
  /// the card.
  final List<String>? expectedFirst;
  final String? intent;
  final List<YtResult> songs, videos;
  final TopCard? card;

  List<ScoredResult> scored() =>
      scoreAll(query, songs: songs, videos: videos, card: card);
}

List<SmartCase> loadSmartCases() => [
      for (final j in jsonDecode(
          File('test/fixtures/smart_search/cases.json').readAsStringSync()) as List)
        SmartCase(j as Map),
    ];

SmartCase smartCase(String query) =>
    loadSmartCases().firstWhere((c) => c.query == query);

/// Best first: confidence, then YouTube Music before YouTube, then position.
List<ScoredResult> ranked(List<ScoredResult> list) => [...list]..sort((a, b) {
    final c = b.confidence.compareTo(a.confidence);
    if (c != 0) return c;
    final s = a.source.index.compareTo(b.source.index);
    return s != 0 ? s : a.position.compareTo(b.position);
  });
