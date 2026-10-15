import '../../core/text_utils.dart';
import '../online/query_cleaner.dart';
import '../online/youtube_service.dart';
import 'exportify_reader.dart';

final _remasterTail = RegExp(
    r'\s+[-–]\s+(\d{4}\s+)?(digital\s+)?remaster(ed)?\b.*$',
    caseSensitive: false);
final _remasterGroup = RegExp(r'[\(\[][^\)\]]*remaster[^\)\]]*[\)\]]',
    caseSensitive: false);
final _featGroup = RegExp(
    r'[\(\[]\s*(feat|ft|featuring|with)\b[^\)\]]*[\)\]]',
    caseSensitive: false);
final _featTail = RegExp(r'\s+[-–]\s+(feat|ft)\b.*$', caseSensitive: false);
final _editGroup = RegExp(
    r'[\(\[]\s*(radio edit|single version|album version|mono|stereo|explicit|remastered)\s*[\)\]]',
    caseSensitive: false);
final _editTail = RegExp(
    r'\s+[-–]\s+(radio edit|single version|album version|mono|stereo|mono version|stereo version)\s*$',
    caseSensitive: false);
final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Lower-case, no accents, no punctuation. Used to compare two spellings of
/// the same name.
String matchKey(String s) =>
    normalize(s.replaceAll('&', ' and ')).replaceAll(_nonWord, ' ').trim();

/// [matchKey] of a title without the qualifiers that do not change the
/// recording (remaster year, feat., radio edit). `live`, `remix`... are kept.
String matchTitleKey(String title) => matchKey(title
    .replaceAll(_remasterGroup, ' ')
    .replaceAll(_featGroup, ' ')
    .replaceAll(_editGroup, ' ')
    .replaceAll(_remasterTail, '')
    .replaceAll(_featTail, '')
    .replaceAll(_editTail, ''));

String _artistKey(String artist) => matchKey(extractPrimaryArtist(artist));

/// Library track as seen by the importer: loaded once, not once per row.
class LibraryEntryLite {
  const LibraryEntryLite({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationMs,
  });

  final int id;
  final String title;
  final String? artist;
  final int durationMs;
}

/// `title|primary artist` -> library tracks; [find] is O(1) per row.
class LibraryIndex {
  LibraryIndex(Iterable<LibraryEntryLite> tracks) {
    for (final t in tracks) {
      _byKey
          .putIfAbsent('${matchTitleKey(t.title)}|${_artistKey(t.artist ?? '')}',
              () => [])
          .add(t);
    }
  }

  final Map<String, List<LibraryEntryLite>> _byKey = {};

  /// Same title and artist; when both lengths are known they must be within 3 s.
  LibraryEntryLite? find(ImportRow r) {
    final c = _byKey['${matchTitleKey(r.title)}|${_artistKey(r.primaryArtist)}'];
    if (c == null) return null;
    final want = r.durationMs;
    for (final t in c) {
      if (want == null || want <= 0 || t.durationMs <= 0) return t;
      if ((t.durationMs - want).abs() <= 3000) return t;
    }
    return null;
  }
}

enum MatchKind { sure, review, notFound }

class ScoredCandidate {
  const ScoredCandidate(this.result, this.score);

  final YtResult result;
  final double score;
}

class MatchDecision {
  const MatchDecision(this.kind, this.top);

  final MatchKind kind;

  /// Best first; at most 3.
  final List<ScoredCandidate> top;

  ScoredCandidate? get best => top.isEmpty ? null : top.first;
}

const sureThreshold = 0.80;
const reviewThreshold = 0.55;

// Versions that are a different recording; ignored when the CSV title asks for them.
const _otherVersions = [
  'live',
  'cover',
  'karaoke',
  'remix',
  'sped up',
  'speed up',
  'slowed',
  'nightcore',
  '8d',
  'instrumental',
  'reverb',
  '1 hour',
  'tribute',
  'acoustic',
  'mashup',
  'demo',
  'parody',
];

bool _hasPhrase(String key, String phrase) => ' $key '.contains(' $phrase ');

Set<String> _tokens(String key) =>
    key.split(' ').where((w) => w.isNotEmpty).toSet();

double _titleScore(String want, String got) {
  final a = _tokens(want), b = _tokens(got);
  if (a.isEmpty || b.isEmpty) return 0;
  final common = a.intersection(b).length;
  final coverage = common / a.length;
  final precision = common / b.length;
  return coverage * (0.6 + 0.4 * precision);
}

double _durationScore(int? wantMs, Duration? got) {
  if (wantMs == null || wantMs <= 0 || got == null) return 0.5;
  final d = (got.inMilliseconds - wantMs).abs() / 1000;
  if (d <= 2) return 1;
  if (d >= 15) return 0;
  return 1 - (d - 2) / 13;
}

final _channelNoise = RegExp(r'\s*[-–]?\s*(topic|vevo|official)$');

double _artistScore(ImportRow r, YtResult c, String titleKey) {
  final want = [for (final a in r.artists) _artistKey(a)]
      .where((a) => a.isNotEmpty)
      .toList();
  if (want.isEmpty) return 0.5;
  final got = <String>{
    for (final a in c.artists) _artistKey(a),
    matchKey(c.channel).replaceFirst(_channelNoise, '').trim(),
  }..remove('');
  if (got.contains(want.first)) return 1;
  if (want.skip(1).any(got.contains)) return 0.8;
  // Plain YouTube uploads: "Artist - Title" in the title or the channel name.
  final hay = ' $titleKey ${matchKey(c.channel)} ';
  if (want.any((a) => hay.contains(' $a '))) return 0.6;
  return 0;
}

double _bonus(ImportRow r, YtResult c) {
  var b = 0.0;
  final channel = matchKey(c.channel);
  if (channel.endsWith(' topic')) b += 0.08;
  if (channel.endsWith('vevo')) b += 0.04;
  if (r.artists.isNotEmpty &&
      channel.replaceFirst(_channelNoise, '').trim() ==
          matchKey(r.primaryArtist)) {
    b += 0.04;
  }
  final album = r.album, got = c.album;
  if (album != null &&
      got != null &&
      matchTitleKey(album) == matchTitleKey(got)) {
    b += 0.04;
  }
  return b > 0.10 ? 0.10 : b;
}

/// 0..1: how likely [c] is the recording described by [r].
double scoreCandidate(ImportRow r, YtResult c) {
  final wantTitle = matchTitleKey(r.title);
  final gotTitle = matchTitleKey(c.title);
  final title = _titleScore(wantTitle, gotTitle);
  final artist = _artistScore(r, c, gotTitle);
  final duration = _durationScore(r.durationMs, c.duration);
  var score = 0.45 * duration + 0.35 * title + 0.20 * artist + _bonus(r, c);
  for (final w in _otherVersions) {
    if (_hasPhrase(gotTitle, w) && !_hasPhrase(wantTitle, w)) {
      score *= 0.4;
      break;
    }
  }
  return score.clamp(0.0, 1.0).toDouble();
}

MatchDecision decide(ImportRow r, List<YtResult> candidates) {
  final scored = [
    for (final c in candidates) ScoredCandidate(c, scoreCandidate(r, c)),
  ]..sort((a, b) => b.score.compareTo(a.score));
  final top = scored.take(3).toList();
  final best = top.isEmpty ? 0.0 : top.first.score;
  if (best >= sureThreshold) return MatchDecision(MatchKind.sure, top);
  if (best >= reviewThreshold) return MatchDecision(MatchKind.review, top);
  return MatchDecision(MatchKind.notFound, const []);
}
